defmodule Binance do
  alias Binance.Rest.HTTPClient

  # Server

  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  def ping() do
    HTTPClient.get_binance("/api/v3/ping")
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
    case HTTPClient.get_binance("/api/v3/time") do
      {:ok, %{"serverTime" => time}} -> {:ok, time}
      err -> err
    end
  end

  def get_exchange_info() do
    case HTTPClient.get_binance("/api/v1/exchangeInfo") do
      {:ok, data} -> {:ok, Binance.ExchangeInfo.new(data)}
      err -> err
    end
  end

  @doc """
  Get historical trades

  Returns `{:ok, [%Binance.HistoricalTrade{}]}` or `{:error, reason}`.

  ## Example
  {:ok,
    []
  }
  """
  def get_historical_trades() do
    case HTTPClient.get_binance("/api/v3/historicalTrades") do
      {:ok, data} ->
        IO.inspect(data)
        {:ok, Binance.HistoricalTrade.new(data)}

      err ->
        err
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
    case HTTPClient.get_binance("/api/v3/ticker/price") do
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
    case HTTPClient.get_binance("/api/v3/ticker/24hr?symbol=#{symbol}") do
      {:ok, data} -> {:ok, Binance.Ticker.new(data)}
      err -> err
    end
  end

  @doc """
  Retrieves klines for a symbol, provided a given interval, e.g. "1h".

  Function can also take in a 'limit' argument to reduce the number of intervals.

  Returns `{:ok, [%Binance.Kline{}]` or `{:error, reason}`

  ## Example
  ```
  {:ok,
  [
   %Binance.Kline{
     close: "0.16527000",
     close_time: 1617861599999,
     high: "0.17100000",
     ignore: "0",
     low: "0.16352000",
     number_of_trades: 16167,
     open: "0.17088000",
     open_time: 1617858000000,
     quote_asset_volume: "7713624.32966000",
     taker_buy_base_asset_volume: "22020677.70000000",
     taker_buy_quote_asset_volume: "3668705.43042700",
     volume: "46282422.20000000"
   },
   %Binance.Kline{
   ...
   ```
  """

  def get_klines(symbol, interval, limit \\ 500) when is_binary(symbol) do
    case HTTPClient.get_binance(
           "/api/v3/klines?symbol=#{symbol}&interval=#{interval}&limit=#{limit}"
         ) do
      {:ok, data} ->
        {:ok, Enum.map(data, &Binance.Kline.new(&1))}

      err ->
        err
    end
  end

  @doc """
  Retrieves the bids & asks of the order book up to the depth for the given symbol

  Returns `{:ok, %{bids: [...], asks: [...], lastUpdateId: 12345}}` or `{:error, reason}`

  ## Example
  ```
  {:ok,
    %Binance.OrderBook{
      asks: [
        ["8400.00000000", "2.04078100", []],
        ["8405.35000000", "0.50354700", []],
        ["8406.00000000", "0.32769800", []],
        ["8406.33000000", "0.00239000", []],
        ["8406.51000000", "0.03241000", []]
      ],
      bids: [
        ["8393.00000000", "0.20453200", []],
        ["8392.57000000", "0.02639000", []],
        ["8392.00000000", "1.40893300", []],
        ["8390.09000000", "0.07047100", []],
        ["8388.72000000", "0.04577400", []]
      ],
      last_update_id: 113634395
    }
  }
  ```
  """
  def get_depth(symbol, limit) do
    case HTTPClient.get_binance("/api/v3/depth?symbol=#{symbol}&limit=#{limit}") do
      {:ok, data} -> {:ok, Binance.OrderBook.new(data)}
      err -> err
    end
  end

  # Account

  @doc """
  Fetches user account from binance

  Returns `{:ok, %Binance.Account{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#account-information-user_data to understand API
  """

  def get_account() do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    case HTTPClient.get_binance("/api/v3/account", %{}, secret_key, api_key) do
      {:ok, data} -> {:ok, Binance.Account.new(data)}
      error -> error
    end
  end

  # User data streams

  @doc """
  Creates a socket listen key that later can be used as parameter to listen for
  user related events.

  Returns `{:ok, %Binance.DataStream{}}` or `{:error, reason}`.

  ## Example
  ```
  {:ok,
    %Binance.DataStream{
      listen_key: "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"
    }
  }
  ```

  For more context please read https://github.com/binance/binance-spot-api-docs/blob/master/user-data-stream.md#create-a-listenkey

  """
  def create_listen_key() do
    case HTTPClient.unsigned_request_binance("/api/v3/userDataStream", "", :post) do
      {:ok, data} -> {:ok, Binance.DataStream.new(data)}
      error -> error
    end
  end

  @doc """
  Socket listen key expires after 30 minutes withouth a pong response, this
  allows keeping it alive.

  Returns `{:ok, %{}}` or `{:error, reason}`.

  For more context please read https://github.com/binance/binance-spot-api-docs/blob/master/user-data-stream.md#pingkeep-alive-a-listenkey

  """
  def keep_alive_listen_key(key) do
    case HTTPClient.unsigned_request_binance(
           "/api/v3/userDataStream",
           "listenKey=#{key}",
           :put
         ) do
      {:ok, data} -> {:ok, data}
      error -> error
    end
  end

  @doc """
  Closes/disables the listen key. To be used when you stop listening to the
  stream.

  Returns `{:ok, %{}}` or `{:error, reason}`.

  For more context please read https://github.com/binance/binance-spot-api-docs/blob/master/user-data-stream.md#close-a-listenkey

  """
  def close_listen_key(key) do
    case HTTPClient.unsigned_request_binance(
           "/api/v3/userDataStream?listenKey=#{key}",
           nil,
           :delete
         ) do
      {:ok, data} -> {:ok, data}
      error -> error
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
      |> Map.merge(
        unless(is_nil(stop_price), do: %{stopPrice: format_price(stop_price)}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(new_client_order_id), do: %{icebergQty: iceberg_quantity}, else: %{})
      )
      |> Map.merge(unless(is_nil(time_in_force), do: %{timeInForce: time_in_force}, else: %{}))
      |> Map.merge(unless(is_nil(price), do: %{price: format_price(price)}, else: %{}))

    case HTTPClient.signed_request_binance("/api/v3/order", arguments, :post) do
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
  def order_limit_buy(symbol, quantity, price, time_in_force \\ "GTC")

  def order_limit_buy(
        %Binance.TradePair{from: from, to: to} = symbol,
        quantity,
        price,
        time_in_force
      )
      when is_number(quantity)
      when is_number(price)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_limit_buy(binance_symbol, quantity, price, time_in_force)
      e -> e
    end
  end

  def order_limit_buy(symbol, quantity, price, time_in_force)
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "BUY", "LIMIT", quantity, price, time_in_force)
    |> parse_order_response
  end

  @doc """
  Creates a new **limit** **sell** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_sell(symbol, quantity, price, time_in_force \\ "GTC")

  def order_limit_sell(
        %Binance.TradePair{from: from, to: to} = symbol,
        quantity,
        price,
        time_in_force
      )
      when is_number(quantity)
      when is_number(price)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_limit_sell(binance_symbol, quantity, price, time_in_force)
      e -> e
    end
  end

  def order_limit_sell(symbol, quantity, price, time_in_force)
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "SELL", "LIMIT", quantity, price, time_in_force)
    |> parse_order_response
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

  defp parse_order_response({:ok, response}) do
    {:ok, Binance.OrderResponse.new(response)}
  end

  defp parse_order_response({
         :error,
         {
           :binance_error,
           %{code: -2010, msg: "Account has insufficient balance for requested action."} = reason
         }
       }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
  end

  # Misc

  defp format_price(num) when is_float(num), do: :erlang.float_to_binary(num, [{:decimals, 8}])
  defp format_price(num) when is_integer(num), do: inspect(num)
  defp format_price(num) when is_binary(num), do: num

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

  # Open orders

  @doc """
  Get all open orders, alternatively open orders by symbol

  Returns `{:ok, [%Binance.Order{}]}` or `{:error, reason}`.

  Weight: 1 for a single symbol; 40 when the symbol parameter is omitted

  ## Example
  ```
  {:ok,
    [%Binance.Order{price: "0.1", origQty: "1.0", executedQty: "0.0", ...},
     %Binance.Order{...},
     %Binance.Order{...},
     %Binance.Order{...},
     %Binance.Order{...},
     %Binance.Order{...},
     ...]}
  ```
  """
  def get_open_orders() do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    case HTTPClient.get_binance("/api/v3/openOrders", %{}, secret_key, api_key) do
      {:ok, data} -> {:ok, Enum.map(data, &Binance.Order.new(&1))}
      err -> err
    end
  end

  def get_open_orders(%Binance.TradePair{} = symbol) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> get_open_orders(binance_symbol)
      e -> e
    end
  end

  def get_open_orders(symbol) when is_binary(symbol) do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    case HTTPClient.get_binance("/api/v3/openOrders", %{:symbol => symbol}, secret_key, api_key) do
      {:ok, data} -> {:ok, Enum.map(data, &Binance.Order.new(&1))}
      err -> err
    end
  end

  # Order

  @doc """
  Get order by symbol, timestamp and either orderId or origClientOrderId are mandatory

  Returns `{:ok, [%Binance.Order{}]}` or `{:error, reason}`.

  Weight: 1

  ## Example
  ```
  {:ok, %Binance.Order{price: "0.1", origQty: "1.0", executedQty: "0.0", ...}}
  ```

  Info: https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#query-order-user_data
  """
  def get_order(
        symbol,
        timestamp,
        order_id \\ nil,
        orig_client_order_id \\ nil,
        recv_window \\ nil
      ) do
    case is_binary(symbol) do
      true ->
        fetch_order(symbol, timestamp, order_id, orig_client_order_id, recv_window)

      false ->
        case find_symbol(symbol) do
          {:ok, binance_symbol} ->
            fetch_order(binance_symbol, timestamp, order_id, orig_client_order_id, recv_window)

          e ->
            e
        end
    end
  end

  def fetch_order(symbol, timestamp, order_id, orig_client_order_id, recv_window)
      when is_binary(symbol)
      when is_integer(timestamp)
      when is_integer(order_id) or is_binary(orig_client_order_id) do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    arguments =
      %{
        symbol: symbol,
        timestamp: timestamp
      }
      |> Map.merge(unless(is_nil(order_id), do: %{orderId: order_id}, else: %{}))
      |> Map.merge(
        unless(
          is_nil(orig_client_order_id),
          do: %{origClientOrderId: orig_client_order_id},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(recv_window), do: %{recvWindow: recv_window}, else: %{}))

    case HTTPClient.get_binance("/api/v3/order", arguments, secret_key, api_key) do
      {:ok, data} -> {:ok, Binance.Order.new(data)}
      err -> err
    end
  end

  @doc """
  Cancel an active order..

  Symbol and either orderId or origClientOrderId must be sent.

  Returns `{:ok, %Binance.Order{}}` or `{:error, reason}`.

  Weight: 1

  Info: https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#cancel-order-trade
  """
  def cancel_order(
        symbol,
        timestamp,
        order_id \\ nil,
        orig_client_order_id \\ nil,
        new_client_order_id \\ nil,
        recv_window \\ nil
      ) do
    case is_binary(symbol) do
      true ->
        cancel_order_(
          symbol,
          timestamp,
          order_id,
          orig_client_order_id,
          new_client_order_id,
          recv_window
        )

      false ->
        case find_symbol(symbol) do
          {:ok, binance_symbol} ->
            cancel_order_(
              binance_symbol,
              timestamp,
              order_id,
              orig_client_order_id,
              new_client_order_id,
              recv_window
            )

          e ->
            e
        end
    end
  end

  defp cancel_order_(
         symbol,
         timestamp,
         order_id,
         orig_client_order_id,
         new_client_order_id,
         recv_window
       )
       when is_binary(symbol)
       when is_integer(timestamp)
       when is_integer(order_id) or is_binary(orig_client_order_id) do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    arguments =
      %{
        symbol: symbol,
        timestamp: timestamp
      }
      |> Map.merge(unless(is_nil(order_id), do: %{orderId: order_id}, else: %{}))
      |> Map.merge(
        unless(
          is_nil(orig_client_order_id),
          do: %{origClientOrderId: orig_client_order_id},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(new_client_order_id),
          do: %{newClientOrderId: new_client_order_id},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(recv_window), do: %{recvWindow: recv_window}, else: %{}))

    case HTTPClient.delete_binance("/api/v3/order", arguments, secret_key, api_key) do
      {:ok, data} -> {:ok, Binance.Order.new(data)}
      err -> err
    end
  end
end
