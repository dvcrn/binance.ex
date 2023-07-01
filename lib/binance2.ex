defmodule Binance2 do
end

docs = Binance.DocsParser.get_documentation()

docs
|> Enum.each(fn api_group ->
  IO.puts("parsing group: #{api_group.group}")

  defmodule Binance.DocsParser.modularize_name(api_group.group) do
    alias Binance.Rest.HTTPClient

    api_group.items
    |> Enum.each(fn item ->
      method = item.method
      path = item.path
      params = item.query
      name = item.name
      url = "/" <> Path.join(path)
      needs_auth = item.needs_auth?

      mandatory_params =
        Enum.filter(params, fn param ->
          param.optional == false
        end)
        |> Enum.map(fn param ->
          %{name: param.name, description: param.description}
        end)
        |> Enum.filter(&(&1.name != "timestamp"))
        |> Enum.filter(&(&1.name != "signature"))

      optional_params =
        Enum.filter(params, fn param ->
          param.optional == true
        end)
        |> Enum.map(fn param ->
          %{name: param.name, description: param.description}
        end)
        |> Enum.filter(&(&1.name != "timestamp"))
        |> Enum.filter(&(&1.name != "signature"))

      # generate mandatory params
      arg_names =
        mandatory_params
        |> Enum.map(&(Map.get(&1, :name) |> String.to_atom() |> Macro.var(nil)))

      @doc """
      METHOD: #{method}

      PATH: #{inspect(path)}

      URL: #{url}

      needs auth: #{inspect(needs_auth)}

      Mandatory params: #{inspect(mandatory_params)}

      Optional params: #{inspect(optional_params)}
      """
      def unquote(Binance.DocsParser.functionize_name(item))(unquote_splicing(arg_names)) do
        binding = binding()

        IO.puts("API call: #{unquote(method)} " <> unquote(url))
        IO.puts("binding:")
        IO.inspect(binding)

        args = %{
          timestamp: :os.system_time(:millisecond)
        }

        if unquote(needs_auth) do
          case HTTPClient.signed_request_binance(unquote(url), args, unquote(method)) do
            {:ok, %{"code" => code, "msg" => msg}} ->
              {:error, {:binance_error, %{code: code, msg: msg}}}

            data ->
              data
          end
        else
          case HTTPClient.unsigned_request_binance(unquote(url), args, unquote(method)) do
            {:ok, %{"code" => code, "msg" => msg}} ->
              {:error, {:binance_error, %{code: code, msg: msg}}}

            data ->
              data
          end
        end
      end
    end)
  end
end)
