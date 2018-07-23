defmodule Binance do
  @endpoint "https://api.binance.com"

  @api_key  Application.get_env(:binance, :api_key)
  @secret_key  Application.get_env(:binance, :secret_key)

  defp get_binance(url, headers \\ []) do
    HTTPoison.get("#{@endpoint}#{url}", headers)
    |> parse_get_response
  end

  defp get_binance(_url, _params, nil, nil),
    do: {:error, {:config_missing, "Secret and API key missing"}}

  defp get_binance(_url, _params, nil, _api_key),
    do: {:error, {:config_missing, "Secret key missing"}}

  defp get_binance(_url, _params, _secret_key, nil),
    do: {:error, {:config_missing, "API key missing"}}

  defp get_binance(url, params, secret_key, api_key) do
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
        @secret_key,
        argument_string
      )
      |> Base.encode16()

    body = "#{argument_string}&signature=#{signature}"

    case HTTPoison.post("#{@endpoint}#{url}", body, [
           {"X-MBX-APIKEY", @api_key}
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

  defp delete_binance(url, headers \\ []) do
    HTTPoison.delete("#{@endpoint}#{url}", headers)
    |> parse_get_response
  end

  defp delete_binance(url, params, secret_key, api_key) do
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

    delete_binance("#{url}?#{argument_string}&signature=#{signature}", headers)
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

  # Server

  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
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

  def get_exchange_info() do
    case get_binance("/api/v1/exchangeInfo") do
      {:ok, data} -> {:ok, Binance.ExchangeInfo.new(data)}
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
    case get_binance("/api/v1/depth?symbol=#{symbol}&limit=#{limit}") do
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
    case get_binance("/api/v3/account", %{}, @secret_key, @api_key) do
      {:ok, data} -> {:ok, Binance.Account.new(data)}
      error -> error
    end
  end

  # Order

  @doc """
    Check an order's status.

    Returns `{:ok, %Binance.OrderResponse{}}` or `{:error, reason}`

    ## Examples

        {:ok,
        %Binance.OrderResponse{
          client_order_id: "web_0319daab853b4e129edfea4345cbda17",
          executed_qty: "0.00000000",
          iceberg_qty: "0.00000000",
          is_working: true,
          order_id: 44730734,
          orig_qty: "3893.00000000",
          price: "0.00003249",
          side: "SELL",
          status: "NEW",
          stop_price: "0.00000000",
          symbol: "ADABTC",
          time: 1531958591439,
          time_in_force: "GTC",
          transact_time: nil,
          type: "LIMIT"
        }}
  """
  def get_order(symbol, orderId) when is_binary(symbol) do
    case get_binance("/api/v3/order", %{symbol: symbol, orderId: orderId}, @secret_key, @api_key) do
      {:ok, data} -> {:ok, Binance.OrderResponse.new(data)}
      err -> err
    end
  end

  @doc"""

  Cancel an active order.

  Returns `{:ok, %Binance.OrderResponse{}}` or `{:error, reason}`

  ## Examples

      iex> Binance.cancel_order "ADABTC", 18845701
      {:ok,
       %Binance.OrderResponse{
         client_order_id: "gO3U4DaFxcAgolV0nunw2U",
         executed_qty: nil,
         iceberg_qty: nil,
         is_working: nil,
         order_id: 18845701,
         orig_qty: nil,
         price: nil,
         side: nil,
         status: nil,
         stop_price: nil,
         symbol: "ADABTC",
         time: nil,
         time_in_force: nil,
         transact_time: nil,
         type: nil
       }}

  """
  def cancel_order(symbol, orderId) when is_binary(symbol) do
    case delete_binance("/api/v3/order", %{symbol: symbol, orderId: orderId}, @secret_key, @api_key) do
      {:ok, data} -> {:ok, Binance.OrderResponse.new(data)}
      err -> err
    end
  end


  @doc """
  Get all open orders on a symbol. Careful when accessing this with no symbol.

  Returns `{:ok, %Binance.OrderResponse{}}` or `{:error, reason}`

  ## Examples

      iex(52)> Binance.open_orders "ADABTC"
      {:ok,
      [
        %Binance.OrderResponse{
          client_order_id: "web_0319daab853b4e129edfea4345cbda17",
          executed_qty: "0.00000000",
          iceberg_qty: "0.00000000",
          is_working: true,
          order_id: 44730734,
          orig_qty: "3893.00000000",
          price: "0.00003249",
          side: "SELL",
          status: "NEW",
          stop_price: "0.00000000",
          symbol: "ADABTC",
          time: 1531958591439,
          time_in_force: "GTC",
          transact_time: nil,
          type: "LIMIT"
        }
      ]}
  """
  def open_orders(), do: execute_open_orders(%{})
  def open_orders(symbol) when is_binary(symbol), do: execute_open_orders(%{symbol: symbol})

  defp execute_open_orders(params) when is_map(params) do
    case get_binance("/api/v3/openOrders", params, @secret_key, @api_key) do
      {:ok, data} -> {:ok, Enum.map(data, &(Binance.OrderResponse.new(&1)))}
      err -> err
    end
  end

  @doc """
    Get all account orders; active, canceled, or filled.

    Returns `{:ok, %Binance.OrderResponse{}}` or `{:error, reason}`

    ## Examples

        iex> Binance.all_orders "ADBTC"
        {:ok,
        [
          %Binance.OrderResponse{
            client_order_id: "web_a26a41e71ca641e8812a444436e7b7cb",
            executed_qty: "3897.00000000",
            iceberg_qty: "0.00000000",
            is_working: true,
            order_id: 31501417,
            orig_qty: "3897.00000000",
            price: "0.00002606",
            side: "BUY",
            status: "FILLED",
            stop_price: "0.00000000",
            symbol: "ADABTC",
            time: 1526363552351,
            time_in_force: "GTC",
            transact_time: nil,
            type: "LIMIT"
          },
          %Binance.OrderResponse{
            client_order_id: "web_0119daab853b4e129edfea4345cbda17",
            executed_qty: "0.00000000",
            iceberg_qty: "0.00000000",
            is_working: true,
            order_id: 44700734,
            orig_qty: "3893.00000000",
            price: "0.00003249",
            side: "SELL",
            status: "NEW",
            stop_price: "0.00000000",
            symbol: "ADABTC",
            time: 1531958591439,
            time_in_force: "GTC",
            transact_time: nil,
            type: "LIMIT"
          }
        ]}
  """
  def all_orders(symbol) when is_binary(symbol), do: execute_all_orders(%{symbol: symbol})
  def all_orders(symbol, timestamp) when is_binary(symbol) and is_integer(timestamp),
    do: execute_all_orders(%{symbol: symbol, timestamp: timestamp})

  defp execute_all_orders(params) when is_map(params) do
    case get_binance("/api/v3/allOrders", params, @secret_key, @api_key) do
      {:ok, data} -> {:ok, Enum.map(data, &(Binance.OrderResponse.new(&1)))}
      err -> err
    end
  end


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
