defmodule Binance.Rest.HTTPClient do
  @endpoint "https://api.binance.com"

  def get_binance(url, headers \\ []) do
    HTTPoison.get("#{@endpoint}#{url}", headers)
    |> parse_get_response
  end

  def get_binance(_url, _params, nil, nil),
    do: {:error, {:config_missing, "Secret and API key missing"}}

  def get_binance(_url, _params, nil, _api_key),
    do: {:error, {:config_missing, "Secret key missing"}}

  def get_binance(_url, _params, _secret_key, nil),
    do: {:error, {:config_missing, "API key missing"}}

  def get_binance(url, params, secret_key, api_key) do
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

    get_binance("#{url}?#{argument_string}&signature=#{signature}", headers)
  end

  def post_binance(url, params) do
    argument_string =
      params
      |> Map.to_list()
      |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join("=") end)
      |> Enum.join("&")

    # generate signature
    signature =
      :crypto.hmac(
        :sha256,
        Application.get_env(:binance, :secret_key),
        argument_string
      )
      |> Base.encode16()

    body = "#{argument_string}&signature=#{signature}"

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

  defp parse_get_response({:ok, response}) do
    response.body
    |> Poison.decode()
    |> parse_response_body
  end

  defp parse_get_response({:error, err}) do
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
