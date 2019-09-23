defmodule Binance.Futures.Rest.HTTPClient do
  @endpoint "https://fapi.binance.com"

  alias Binance.Util

  def get_binance(url, headers \\ []) do
    "#{@endpoint}#{url}"
    |> HTTPoison.get(headers)
    |> parse_response
  end

  def delete_binance(url, headers \\ []) do
    "#{@endpoint}#{url}"
    |> HTTPoison.delete(headers)
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
    # Binance does require us to sign this request
    body = Util.prepare_request_body(params, true)

    case HTTPoison.post("#{@endpoint}#{url}", body, [
           {"X-MBX-APIKEY", Application.get_env(:binance, :api_key)},
           {"Content-Type", "application/x-www-form-urlencoded"}
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
    # Binance does require us to sign this request
    body = Util.prepare_request_body(params, true)

    case HTTPoison.put("#{@endpoint}#{url}", body, [
           {"X-MBX-APIKEY", Application.get_env(:binance, :api_key)},
           {"Content-Type", "application/x-www-form-urlencoded"}
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
end
