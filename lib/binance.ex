defmodule Binance do
  @endpoint "https://api.binance.com"

  defp get_binance(url) do
    case HTTPoison.get("#{@endpoint}#{url}") do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  defp post_binance(url, params) do
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

  # Server

  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise

  ## Example
    iex> Binance.ping()
    {:ok, %{}}
  """
  def ping() do
    get_binance("/api/v1/ping")
  end

  @doc """
  Get binance server time in unix epoch.

  Returns `{:ok, time}` if successful, `{:error, reason}` otherwise

  ## Example
  ```
  {:ok, 1515390701097}
  ```

  """
  def get_server_time() do
    case get_binance("/api/v1/time") do
      {:ok, %{"serverTime" => time}} -> {:ok, time}
      err -> err
    end
  end

  # Ticker

  @doc """
  Get all symbols and current prices listed in binance

  Returns `{:ok, [%Binance.SymbolPrice{}]}` or `{:error, reason}`.

  ## Example
  ```
  {:ok,
    [%Binance.SymbolPrice{price: "0.07579300", symbol: "ETHBTC"},
     %Binance.SymbolPrice{price: "0.01670200", symbol: "LTCBTC"},
     %Binance.SymbolPrice{price: "0.00114550", symbol: "BNBBTC"},
     %Binance.SymbolPrice{price: "0.00640000", symbol: "NEOBTC"},
     %Binance.SymbolPrice{price: "0.00030000", symbol: "123456"},
     %Binance.SymbolPrice{price: "0.04895000", symbol: "QTUMETH"},
     ...]}
  ```
  """
  def get_all_prices() do
    case get_binance("/api/v1/ticker/allPrices") do
      {:ok, data} ->
        {:ok, Enum.map(data, &Binance.SymbolPrice.new(&1))}

      err ->
        err
    end
  end

  @doc """
  Retrieves the current ticker information for the given trade pair.

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %Binance.Ticker{}}` or `{:error, reason}`

  ## Example
  ```
  {:ok,
    %Binance.Ticker{ask_price: "0.07548800", bid_price: "0.07542100",
      close_time: 1515391124878, count: 661676, first_id: 16797673,
      high_price: "0.07948000", last_id: 17459348, last_price: "0.07542000",
      low_price: "0.06330000", open_price: "0.06593800", open_time: 1515304724878,
      prev_close_price: "0.06593800", price_change: "0.00948200",
      price_change_percent: "14.380", volume: "507770.18500000",
      weighted_avg_price: "0.06946930"}}
  ```
  """
  def get_ticker(%Binance.TradePair{} = symbol) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> get_ticker(binance_symbol)
      e -> e
    end
  end

  def get_ticker(symbol) when is_binary(symbol) do
    case get_binance("/api/v1/ticker/24hr?symbol=#{symbol}") do
      {:ok, data} -> {:ok, Binance.Ticker.new(data)}
      err -> err
    end
  end

  # Order

  @doc """
  Creates a new order on binance

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://www.binance.com/restapipub.html#user-content-account-endpoints to understand all the parameters
  """
  def create_order(
        symbol,
        side,
        type,
        quantity,
        price \\ nil,
        time_in_force \\ nil,
        new_client_order_id \\ nil,
        stop_price \\ nil,
        iceberg_quantity \\ nil,
        receiving_window \\ 1000,
        timestamp \\ nil
      ) do
    timestamp =
      case timestamp do
        # timestamp needs to be in milliseconds
        nil ->
          :os.system_time(:millisecond)

        t ->
          t
      end

    arguments =
      %{
        symbol: symbol,
        side: side,
        type: type,
        quantity: quantity,
        timestamp: timestamp,
        recvWindow: receiving_window
      }
      |> Map.merge(
        unless(
          is_nil(new_client_order_id),
          do: %{newClientOrderId: new_client_order_id},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(new_client_order_id), do: %{stopPrice: stop_price}, else: %{}))
      |> Map.merge(
        unless(is_nil(new_client_order_id), do: %{icebergQty: iceberg_quantity}, else: %{})
      )
      |> Map.merge(unless(is_nil(time_in_force), do: %{timeInForce: time_in_force}, else: %{}))
      |> Map.merge(unless(is_nil(price), do: %{price: price}, else: %{}))

    case post_binance("/api/v3/order", arguments) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  @doc """
  Creates a new **limit** **buy** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_buy(%Binance.TradePair{from: from, to: to} = symbol, quantity, price)
      when is_number(quantity)
      when is_number(price)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_limit_buy(binance_symbol, quantity, price)
      e -> e
    end
  end

  def order_limit_buy(symbol, quantity, price)
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "BUY", "LIMIT", quantity, price, "GTC")
  end

  @doc """
  Creates a new **limit** **sell** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_sell(%Binance.TradePair{from: from, to: to} = symbol, quantity, price)
      when is_number(quantity)
      when is_number(price)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_limit_sell(binance_symbol, quantity, price)
      e -> e
    end
  end

  def order_limit_sell(symbol, quantity, price)
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "SELL", "LIMIT", quantity, price, "GTC")
  end

  @doc """
  Creates a new **market** **buy** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_market_buy(%Binance.TradePair{from: from, to: to} = symbol, quantity)
      when is_number(quantity)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_market_buy(binance_symbol, quantity)
      e -> e
    end
  end

  def order_market_buy(symbol, quantity)
      when is_binary(symbol)
      when is_number(quantity) do
    create_order(symbol, "BUY", "MARKET", quantity)
  end

  @doc """
  Creates a new **market** **sell** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_market_sell(%Binance.TradePair{from: from, to: to} = symbol, quantity)
      when is_number(quantity)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_market_sell(binance_symbol, quantity)
      e -> e
    end
  end

  def order_market_sell(symbol, quantity)
      when is_binary(symbol)
      when is_number(quantity) do
    create_order(symbol, "SELL", "MARKET", quantity)
  end

  # Misc

  @doc """
  Searches and normalizes the symbol as it is listed on binance.

  To retrieve this information, a request to the binance API is done. The result is then **cached** to ensure the request is done only once.

  Order of which symbol comes first, and case sensitivity does not matter.

  Returns `{:ok, "SYMBOL"}` if successfully, or `{:error, reason}` otherwise.

  ## Examples
  These 3 calls will result in the same result string:
  ```
  find_symbol(%Binance.TradePair{from: "ETH", to: "REQ"})
  ```
  ```
  find_symbol(%Binance.TradePair{from: "REQ", to: "ETH"})
  ```
  ```
  find_symbol(%Binance.TradePair{from: "rEq", to: "eTH"})
  ```

  Result: `{:ok, "REQETH"}`

  """
  def find_symbol(%Binance.TradePair{from: from, to: to} = tp)
      when is_binary(from)
      when is_binary(to) do
    case Binance.SymbolCache.get() do
      # cache hit
      {:ok, data} ->
        from = String.upcase(from)
        to = String.upcase(to)

        found = Enum.filter(data, &Enum.member?([from <> to, to <> from], &1))

        case Enum.count(found) do
          1 -> {:ok, found |> List.first()}
          0 -> {:error, :symbol_not_found}
        end

      # cache miss
      {:error, :not_initialized} ->
        case get_all_prices() do
          {:ok, price_data} ->
            price_data
            |> Enum.map(fn x -> x.symbol end)
            |> Binance.SymbolCache.store()

            find_symbol(tp)

          err ->
            err
        end

      err ->
        err
    end
  end
end
