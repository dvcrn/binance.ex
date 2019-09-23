defmodule Binance.Rest.HTTPClient do
  @endpoint "https://api.binance.com"

  def get_binance(url, headers \\ []) do
    HTTPoison.get("#{@endpoint}#{url}", headers)
    |> parse_response
  end

  def delete_binance(url, headers \\ []) do
    HTTPoison.delete("#{@endpoint}#{url}", headers)
    |> parse_response
  end

  def get_binance(url, params, secret_key, api_key) do
    case prepare_request(url, params, secret_key, api_key) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        get_binance(url, headers)
    end
  end

  def delete_binance(url, params, secret_key, api_key) do
    case prepare_request(url, params, secret_key, api_key) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        delete_binance(url, headers)
    end
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
          :crypto.hmac(
            :sha256,
            secret_key,
            argument_string
          )
          |> Base.encode16()

        {:ok, "#{url}?#{argument_string}&signature=#{signature}", headers}
    end
  end

  def post_binance(url, params) do
    body = prepare_body(params, false)

    case HTTPoison.post("#{@endpoint}#{url}", body, [
           {"X-MBX-APIKEY", Application.get_env(:binance, :api_key)}
         ]) do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  def put_binance(url, params) do
    body = prepare_body(params, false)

    case HTTPoison.put("#{@endpoint}#{url}", body, [
           {"X-MBX-APIKEY", Application.get_env(:binance, :api_key)}
         ]) do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, %{body: ""}} ->
        {:ok, ""}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  defp validate_credentials(nil, nil),
    do: {:error, {:config_missing, "Secret and API key missing"}}

  defp validate_credentials(nil, _api_key), do: {:error, {:config_missing, "Secret key missing"}}

  defp validate_credentials(_secret_key, nil), do: {:error, {:config_missing, "API key missing"}}

  defp validate_credentials(_secret_key, _api_key), do: :ok

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

  defp prepare_body(params, sign?) do
    argument_string =
      params
      |> Map.to_list()
      |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join("=") end)
      |> Enum.join("&")

    case sign? do
      true ->
        signature = sign_content(argument_string)
        "#{argument_string}&signature=#{signature}"

      false ->
        argument_string
    end
  end

  defp sign_content(content) do
    :crypto.hmac(
      :sha256,
      Application.get_env(:binance, :secret_key),
      content
    )
    |> Base.encode16()
  end
end
