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
      needs_timestamp = item.needs_timestamp?
      description = item.description
      fx_name = item.fx_name

      IO.puts("  generating #{fx_name} (#{url})")

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

      spec =
        mandatory_params
        |> Enum.map(fn _item -> quote do: any() end)

      optional_args =
        optional_params
        |> Enum.reduce([], fn item, acc ->
          name = item.name

          case acc do
            [] ->
              quote do: {unquote(String.to_atom(name)), any()}

            val ->
              quote do:
                      {unquote(String.to_atom(name)), any()}
                      | unquote(val)
          end
        end)
        |> case do
          [] -> []
          e -> [e]
        end

      @doc """
      #{name}

      #{description}

      Details:

      - METHOD: #{method}
      - URL: #{url}

      Mandatory params:

      #{Enum.map(mandatory_params, fn item -> "- #{item.name} - #{item.description}" end) |> Enum.join("\n")}

      Optional params:

      #{Enum.map(optional_params, fn item -> "- #{item.name} - #{item.description}" end) |> Enum.join("\n")}
      """

      # fx without opts
      @spec unquote(fx_name)(unquote_splicing(spec)) ::
              {:ok, any()} | {:error, any()}

      # fx with opts
      @spec unquote(fx_name)(
              unquote_splicing(spec),
              unquote(optional_args)
            ) ::
              {:ok, any()} | {:error, any()}

      def unquote(fx_name)(
            unquote_splicing(arg_names),
            opts \\ []
          ) do
        binding = binding()

        # merge all passed args together, so opts + passed
        all_passed_args = Keyword.merge(binding, opts) |> Keyword.drop([:opts])

        IO.puts("API call: #{unquote(method)} " <> unquote(url))
        IO.puts("binding:")
        IO.inspect(binding)
        IO.puts("passed args:")
        IO.inspect(all_passed_args)

        # if the call requires a timestamp, we add it
        adjusted_args =
          case unquote(needs_timestamp) do
            false ->
              all_passed_args

            true ->
              case Keyword.has_key?(all_passed_args, :timestamp) do
                false ->
                  Keyword.put_new(all_passed_args, :timestamp, :os.system_time(:millisecond))

                true ->
                  all_passed_args
              end
          end
          |> Enum.into(%{})

        IO.puts("adjusted args:")
        IO.inspect(all_passed_args)

        if unquote(needs_auth) do
          case HTTPClient.signed_request_binance(unquote(url), adjusted_args, unquote(method)) do
            {:ok, %{"code" => code, "msg" => msg}} ->
              {:error, {:binance_error, %{code: code, msg: msg}}}

            data ->
              data
          end
        else
          case HTTPClient.unsigned_request_binance(unquote(url), adjusted_args, unquote(method)) do
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
