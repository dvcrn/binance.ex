defmodule Binance.Rest.FlexBaseClient do
  alias Binance.{Config, Util}

  require Logger

  def get_binance(endpoint, url, headers \\ []) when is_list(headers) do
    HTTPoison.get("#{endpoint}#{url}", headers)
    |> parse_response
  end

  def delete_binance(endpoint, url, headers \\ []) when is_list(headers) do
    HTTPoison.delete("#{endpoint}#{url}", headers)
    |> parse_response
  end

  def get_binance(endpoint, url, params, config) do
    case prepare_request(:get, url, params, config, true) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        get_binance(endpoint, url, headers)
    end
  end

  def delete_binance(endpoint, url, params, config) do
    case prepare_request(:delete, url, params, config, true) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        delete_binance(endpoint, url, headers)
    end
  end

  def post_binance(endpoint, url, params, config, signed? \\ true) do
    case prepare_request(:post, url, params, config, signed?) do
      {:error, _} = error ->
        error

      {:ok, url, headers, body} ->
        case HTTPoison.post("#{endpoint}#{url}", body, headers) do
          {:error, err} ->
            {:error, {:http_error, err}, nil}

          {:ok, %{status_code: status_code} = response} when status_code not in 200..299 ->
            case Poison.decode(response.body) do
              {:ok, %{"code" => code, "msg" => msg}} ->
                {:error, {:binance_error, %{code: code, msg: msg}}, response.headers}

              {:error, err} ->
                if System.get_env("DEBUG_LOG") === "true" do
                  Logger.error("poison_decode_error: #{inspect(response.body)}")
                end

                {:error, {:poison_decode_error, err}, response.headers}
            end

          {:ok, response} ->
            case Poison.decode(response.body) do
              {:ok, data} ->
                {:ok, data, response.headers}

              {:error, err} ->
                if System.get_env("DEBUG_LOG") === "true" do
                  Logger.error("poison_decode_error: #{inspect(response.body)}")
                end

                {:error, {:poison_decode_error, err}, response.headers}
            end
        end
    end
  end

  def put_binance(endpoint, url, params, config, signed? \\ true) do
    case prepare_request(:put, url, params, config, signed?) do
      {:error, _} = error ->
        error

      {:ok, url, headers, body} ->
        case HTTPoison.put("#{endpoint}#{url}", body, headers) do
          {:error, err} ->
            {:error, {:http_error, err}, nil}

          {:ok, %{status_code: status_code} = response} when status_code not in 200..299 ->
            case Poison.decode(response.body) do
              {:ok, %{"code" => code, "msg" => msg}} ->
                {:error, {:binance_error, %{code: code, msg: msg}}, response.headers}

              {:error, err} ->
                if System.get_env("DEBUG_LOG") === "true" do
                  Logger.error("poison_decode_error: #{inspect(response.body)}")
                end

                {:error, {:poison_decode_error, err}, response.headers}
            end

          {:ok, %{body: "", headers: headers}} ->
            {:ok, "", headers}

          {:ok, response} ->
            case Poison.decode(response.body) do
              {:ok, data} ->
                {:ok, data, response.headers}

              {:error, err} ->
                if System.get_env("DEBUG_LOG") === "true" do
                  Logger.error("poison_decode_error: #{inspect(response.body)}")
                end

                {:error, {:poison_decode_error, err}, response.headers}
            end
        end
    end
  end

  defp prepare_request(method, url, params, config, signed?) do
    case validate_credentials(config) do
      {:error, _} = error ->
        error

      {:ok, %Config{api_key: api_key, api_secret: api_secret, api_secret_type: api_secret_type}} ->
        cond do
          method in [:get, :delete] ->
            headers = [
              {"X-MBX-APIKEY", api_key}
            ]

            params =
              Map.merge(params, %{
                timestamp: :os.system_time(:millisecond)
              })

            argument_string = URI.encode_query(params)
            signature = Util.sign_content(api_secret, argument_string, api_secret_type)

            {:ok, "#{url}?#{argument_string}&signature=#{signature}", headers}

          method in [:post, :put] ->
            headers = [
              {"X-MBX-APIKEY", api_key},
              {"Content-Type", "application/x-www-form-urlencoded"}
            ]

            argument_string = URI.encode_query(params)

            argument_string =
              case signed? do
                true ->
                  signature = Util.sign_content(api_secret, argument_string, api_secret_type)
                  "#{argument_string}&signature=#{signature}"

                false ->
                  argument_string
              end

            {:ok, url, headers, argument_string}
        end
    end
  end

  defp validate_credentials(config) do
    case Config.get(config) do
      %Config{api_key: api_key, api_secret: api_secret} = config
      when is_binary(api_key) and is_binary(api_secret) ->
        {:ok, config}

      _ ->
        {:error, {:config_missing, "Secret or API key missing"}}
    end
  end

  defp parse_response({:error, err}) do
    {:error, {:http_error, err}, nil}
  end

  defp parse_response({:ok, %{status_code: status_code} = response})
       when status_code not in 200..299 do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, response.headers}

      {:error, error} ->
        if System.get_env("DEBUG_LOG") === "true" do
          Logger.error("poison_decode_error: #{inspect(response.body)}")
        end

        {:error, {:poison_decode_error, error}, response.headers}
    end
  end

  defp parse_response({:ok, response}) do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, data} ->
        {:ok, data, response.headers}

      {:error, error} ->
        if System.get_env("DEBUG_LOG") === "true" do
          Logger.error("poison_decode_error: #{inspect(response.body)}")
        end

        {:error, {:poison_decode_error, error}, response.headers}
    end
  end
end
