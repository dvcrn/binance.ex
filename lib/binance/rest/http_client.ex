defmodule Binance.Rest.HTTPClient do
  defp endpoint() do
    Application.get_env(:binance, :end_point, "https://api.binance.com")
  end

  defp prepare_request(url, params, secret_key, api_key) do
    case validate_credentials(secret_key, api_key) do
      {:error, _} = error ->
        error

      _ ->
        headers = [{"X-MBX-APIKEY", api_key}]
        receive_window = 5000
        ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

        params =
          Map.merge(params, %{
            timestamp: ts,
            recvWindow: receive_window
          })

        argument_string = URI.encode_query(params)

        signature =
          generate_signature(
            :sha256,
            secret_key,
            argument_string
          )
          |> Base.encode16()

        {:ok, "#{url}?#{argument_string}&signature=#{signature}", headers}
    end
  end

  defp request_binance(api_key, url, body, method) do
    url = URI.parse("#{endpoint()}#{url}")

    encoded_url =
      if body != "" do
        URI.append_query(url, body)
      else
        url
      end

    case method do
      :get ->
        HTTPoison.get(
          URI.to_string(encoded_url),
          [
            {"X-MBX-APIKEY", api_key},
          ]
        )

      :delete ->
        HTTPoison.delete(
          URI.to_string(encoded_url),
          [
            {"X-MBX-APIKEY", api_key},
          ]
        )

      _ ->
        apply(HTTPoison, method, [
          URI.to_string(encoded_url),
          "",
          [
            {"X-MBX-APIKEY", api_key},
          ]
        ])
    end
    |> case do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  def signed_request_binance(api_key, secret_key, url, params, method) do
    argument_string =
      params
      |> prepare_query_params()

    # generate signature
    signature =
      generate_signature(
        :sha256,
        secret_key,
        argument_string
      )
      |> Base.encode16()

    body = "#{argument_string}&signature=#{signature}"

    request_binance(api_key, url, body, method)
  end

  @doc """
  You need to send an empty body and the api key
  to be able to create a new listening key.

  """
  def unsigned_request_binance(url, data, method) do
    argument_string =
      data
      |> prepare_query_params()

    request_binance("", url, argument_string, method)
  end

  defp validate_credentials(nil, nil),
    do: {:error, {:config_missing, "Secret and API key missing"}}

  defp validate_credentials(nil, _api_key),
    do: {:error, {:config_missing, "Secret key missing"}}

  defp validate_credentials(_secret_key, nil),
    do: {:error, {:config_missing, "API key missing"}}

  defp validate_credentials(_secret_key, _api_key),
    do: :ok

  defp parse_response({:ok, response}) do
    response.body
    |> Poison.decode()
    |> parse_response_body
  end

  defp parse_response({:error, err}) do
    {:error, {:http_error, err}}
  end

  defp parse_response_body({:ok, data}) do
    case data do
      %{"code" => _c, "msg" => _m} = error -> {:error, error}
      _ -> {:ok, data}
    end
  end

  defp parse_response_body({:error, err}) do
    {:error, {:poison_decode_error, err}}
  end

  defp prepare_query_params(params) do
    params
    |> Map.to_list()
    |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join("=") end)
    |> Enum.join("&")
  end

  defp generate_signature(digest, key, argument_string),
    do: :crypto.mac(:hmac, digest, key, argument_string)
end
