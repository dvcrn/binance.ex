defmodule Binance do
  defmodule Helper do
    def format_price(num) when is_float(num), do: :erlang.float_to_binary(num, [{:decimals, 8}])
    def format_price(num) when is_integer(num), do: inspect(num)
    def format_price(num) when is_binary(num), do: num

    @doc """
    Either returns a specific error (if we have one), or formats as generic {:binance_error, xxx}
    """
    def format_error(%{"code" => -2010, "msg" => msg}),
      do: {:binance_error, %Binance.Errors.InsufficientBalanceError{code: -2010, msg: msg}}

    def format_error(%{"code" => code, "msg" => msg}) do
      {:binance_error, %{code: code, msg: msg}}
    end

    @doc """
    Converts a map with string keys into a map with atoms

    This is considered unsafe since atoms are never garbage collected and can cause a memory leak
    """
    def keys_to_atoms(string_key_map) when is_map(string_key_map) do
      for {key, val} <- string_key_map,
          into: %{},
          do: {
            String.to_atom(key),
            keys_to_atoms(val)
          }
    end

    def keys_to_atoms(value) when is_list(value), do: Enum.map(value, &keys_to_atoms/1)
    def keys_to_atoms(value), do: value
  end
end

docs = Binance.DocsParser.get_documentation()

docs
|> Enum.each(fn api_group ->
  # IO.puts("### Group: #{api_group.group}")

  defmodule Binance.DocsParser.modularize_name(api_group.group) do
    alias Binance.Rest.HTTPClient

    @moduledoc """
    #{api_group.description}
    """

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
      path_key = item.path_key

      # IO.puts("- #{fx_name} (#{path_key})")

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
        |> Kernel.++([
          %{name: "api_key", description: "Binance API key, will overwrite env key"},
          %{name: "api_secret", description: "Binance API secret, will overwrite env secret"}
        ])

      optional_params =
        case needs_timestamp do
          true ->
            [%{name: "timestamp", description: "timestamp"} | optional_params]

          _ ->
            optional_params
        end

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
        all_passed_args =
          Keyword.merge(binding, opts) |> Keyword.drop([:opts, :api_key, :secret_key])

        api_key =
          Keyword.get(opts, :api_key) || Application.get_env(:binance, :api_key, "")

        secret_key =
          Keyword.get(opts, :secret_key) || Application.get_env(:binance, :secret_key, "")

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
          # special handling for certain parameters like price:
          |> Enum.map(fn {k, v} ->
            case k do
              :price ->
                {k, Binance.Helper.format_price(v)}

              _ ->
                {k, v}
            end
          end)
          |> Enum.into(%{})

        case unquote(needs_auth) do
          true ->
            case HTTPClient.signed_request_binance(
                   unquote(url),
                   api_key,
                   secret_key,
                   adjusted_args,
                   unquote(method)
                 ) do
              {:ok, %{"code" => _code, "msg" => _msg} = err} ->
                {:error, Binance.Helper.format_error(err)}

              data ->
                data
            end

          false ->
            case HTTPClient.unsigned_request_binance(
                   unquote(url),
                   adjusted_args,
                   unquote(method)
                 ) do
              {:ok, %{"code" => _code, "msg" => _msg} = err} ->
                {:error, Binance.Helper.format_error(err)}

              data ->
                data
            end
        end
        |> case do
          {:ok, data} ->
            # try to find a response mapped struct
            case Binance.ResponseMapping.lookup(unquote(path_key)) do
              nil ->
                {:ok, Binance.Helper.keys_to_atoms(data)}

              struct_name ->
                {:ok, struct_name.new(data)}
            end

          e ->
            e
        end
      end
    end)
  end
end)
