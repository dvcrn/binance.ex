defmodule Binance do
  alias Binance.Rest.HTTPClient

  # Server

  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  def ping() do
    HTTPClient.get_binance("/api/v1/ping")
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
    case HTTPClient.get_binance("/api/v1/time") do
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
  Start a new user data stream. The stream will close after 60 minutes unless a keepalive is sent.

  Returns `{:ok, time}` if successful, `{:error, reason}` otherwise

  ## Example response
  ```
  {
    "listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"
  }
  ```

  Note: Binance Spot does not require us to sign this request body while this very same API on Binance Futures does

  """
  def create_listen_key(config \\ nil) do
    case HTTPClient.post_binance("/api/v1/userDataStream", %{}, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  @doc """
  Keepalive a user data stream to prevent a time out. User data streams will close after 60 minutes. It's recommended to send a ping about every 30 minutes.

  Returns `{:ok, time}` if successful, `{:error, reason}` otherwise

  ## Example response
  ```
  {}
  ```

  Note: Binance Spot does not require us to sign this request body while this very same API on Binance Futures does

  """
  def keep_alive_listen_key(listen_key, config \\ nil) do
    arguments = %{
      listenKey: listen_key
    }

    case HTTPClient.put_binance("/api/v1/userDataStream", arguments, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
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
    case HTTPClient.get_binance("/api/v1/ticker/allPrices") do
      {:ok, data} ->
        {:ok, Enum.map(data, &Binance.SymbolPrice.new(&1))}

      err ->
        err
    end
  end

  @doc """
  Retrieves the current ticker information for the given trade pair.

  Symbol can be a binance symbol in the form of `"ETHBTC"`.

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
  def get_ticker(symbol) when is_binary(symbol) do
    case HTTPClient.get_binance("/api/v1/ticker/24hr?symbol=#{symbol}") do
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
    case HTTPClient.get_binance("/api/v1/depth?symbol=#{symbol}&limit=#{limit}") do
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

  def get_account(config \\ nil) do
    case HTTPClient.get_binance("/api/v3/account", %{}, config) do
      {:ok, data} -> {:ok, Binance.Account.new(data)}
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
        %{symbol: symbol, side: side, type: type, quantity: quantity} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      side: side,
      type: type,
      quantity: quantity,
      timestamp: params[:timestamp] || :os.system_time(:millisecond),
      recvWindow: params[:recv_window] || 1000
    }

    arguments =
      arguments
      |> Map.merge(
        unless(
          is_nil(params[:new_client_order_id]),
          do: %{newClientOrderId: params[:new_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:stop_price]), do: %{stopPrice: params[:stop_price]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:new_client_order_id]),
          do: %{icebergQty: params[:iceberg_quantity]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:time_in_force]),
          do: %{timeInForce: params[:time_in_force]},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(params[:price]), do: %{price: params[:price]}, else: %{}))

    case HTTPClient.post_binance("/api/v3/order", arguments, config) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}} |> parse_order_response

      data ->
        data |> parse_order_response
    end
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

  # Open orders

  @doc """
  Get all open orders, alternatively open orders by symbol (params[:symbol])

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
  def get_open_orders(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("/api/v3/openOrders", params, config) do
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
  def get_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol],
        timestamp: params[:timestamp] || :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:order_id]), do: %{orderId: params[:order_id]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:orig_client_order_id]),
          do: %{origClientOrderId: params[:orig_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    case HTTPClient.get_binance("/api/v3/order", arguments, config) do
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
  def cancel_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol],
        timestamp: params[:timestamp] || :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:order_id]), do: %{orderId: params[:order_id]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:orig_client_order_id]),
          do: %{origClientOrderId: params[:orig_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:new_client_order_id]),
          do: %{newClientOrderId: params[:new_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:recv_window]),
          do: %{recvWindow: params[:recv_window]},
          else: %{}
        )
      )

    case HTTPClient.delete_binance("/api/v3/order", arguments, config) do
      {:ok, data} -> {:ok, Binance.Order.new(data)}
      err -> err
    end
  end
end
