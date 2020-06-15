defmodule Binance do
  alias Binance.Rest.HTTPClient

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  # Server

  @doc """
  Pings binance API
  """
  @spec ping() :: {:ok, %{}} | {:error, error()}
  def ping() do
    HTTPClient.get_binance("/api/v3/ping")
  end

  @doc """
  Get binance server time in unix epoch.

  ## Example
  ```
  {:ok, 1515390701097}
  ```

  """
  @spec get_server_time() :: {:ok, integer()} | {:error, error()}
  def get_server_time() do
    case HTTPClient.get_binance("/api/v3/time") do
      {:ok, %{"serverTime" => time}} -> {:ok, time}
      err -> err
    end
  end

  @spec get_exchange_info() :: {:ok, %Binance.ExchangeInfo{}} | {:error, error()}
  def get_exchange_info() do
    case HTTPClient.get_binance("/api/v3/exchangeInfo") do
      {:ok, data} -> {:ok, Binance.ExchangeInfo.new(data)}
      err -> err
    end
  end

  @spec get_best_ticker(String.t()) :: {:ok, map()} | {:error, error()}
  def get_best_ticker(instrument) do
    case HTTPClient.get_binance("/api/v3/ticker/bookTicker?symbol=#{instrument}") do
      {:ok, data} -> {:ok, data}
      err -> err
    end
  end

  @doc """
  Start a new user data stream. The stream will close after 60 minutes unless a keepalive is sent.

  ## Example response
  ```
  {
    "listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"
  }
  ```

  Note: Binance Spot does not require us to sign this request body while this very same API on Binance Futures does

  """
  @spec create_listen_key(map() | nil) :: {:ok, map()} | {:error, error()}
  def create_listen_key(config \\ nil) do
    case HTTPClient.post_binance("/api/v3/userDataStream", %{}, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  @doc """
  Keepalive a user data stream to prevent a time out. User data streams will close after 60 minutes. It's recommended to send a ping about every 30 minutes.

  ## Example response
  ```
  {}
  ```

  Note: Binance Spot does not require us to sign this request body while this very same API on Binance Futures does

  """
  @spec keep_alive_listen_key(String.t(), map() | nil) :: {:ok, %{}} | {:error, error()}
  def keep_alive_listen_key(listen_key, config \\ nil) do
    arguments = %{
      listenKey: listen_key
    }

    case HTTPClient.put_binance("/api/v3/userDataStream", arguments, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  # Ticker

  @doc """
  Retrieves the current ticker information for the given trade pair.

  Symbol can be a binance symbol in the form of `"ETHBTC"`.

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
  @spec get_ticker(String.t()) :: {:ok, %Binance.Ticker{}} | {:error, error()}
  def get_ticker(symbol) when is_binary(symbol) do
    case HTTPClient.get_binance("/api/v3/ticker/24hr?symbol=#{symbol}") do
      {:ok, data} -> {:ok, Binance.Ticker.new(data)}
      err -> err
    end
  end

  @doc """
  Retrieves the bids & asks of the order book up to the depth for the given symbol

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
  @spec get_depth(String.t(), integer()) :: {:ok, %Binance.OrderBook{}} | {:error, error()}
  def get_depth(symbol, limit) do
    case HTTPClient.get_binance("/api/v3/depth?symbol=#{symbol}&limit=#{limit}") do
      {:ok, data} -> {:ok, Binance.OrderBook.new(data)}
      err -> err
    end
  end

  # Account

  @doc """
  Fetches user account from binance

  In the case of a error on binance, for example with invalid parameters, `{:error, Binance.error()}` will be returned.

  Please read https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#account-information-user_data to understand API
  """

  @spec get_account(map() | nil) :: {:ok, %Binance.Account{}} | {:error, error()}
  def get_account(config \\ nil) do
    case HTTPClient.get_binance("/api/v3/account", %{}, config) do
      {:ok, data} -> {:ok, Binance.Account.new(data)}
      error -> error
    end
  end

  # Order

  @doc """
  Creates a new order on binance

  Please read https://www.binance.com/restapipub.html#user-content-account-endpoints to understand all the parameters
  """
  @spec create_order(map(), map() | nil) :: {:ok, map()} | {:error, error()}
  def create_order(
        %{symbol: symbol, side: side, type: type, quantity: quantity} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      side: side,
      type: type,
      quantity: quantity,
      timestamp: params[:timestamp] || :os.system_time(:millisecond)
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
          is_nil(params[:iceberg_quantity]),
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
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    case HTTPClient.post_binance("/api/v3/order", arguments, config) do
      {:ok, data} ->
        {:ok, Binance.OrderResponse.new(data)}

      error ->
        error
    end
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
  @spec get_open_orders(map(), map() | nil) :: {:ok, list(%Binance.Order{})} | {:error, error()}
  def get_open_orders(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("/api/v3/openOrders", params, config) do
      {:ok, data} -> {:ok, Enum.map(data, &Binance.Order.new(&1))}
      err -> err
    end
  end

  # Order

  @doc """
  Get order by symbol, timestamp and either orderId or origClientOrderId are mandatory

  Weight: 1

  ## Example
  ```
  {:ok, %Binance.Order{price: "0.1", origQty: "1.0", executedQty: "0.0", ...}}
  ```

  Info: https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#query-order-user_data
  """
  @spec get_order(map(), map() | nil) :: {:ok, list(%Binance.Order{})} | {:error, error()}
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

  Weight: 1

  Info: https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#cancel-order-trade
  """
  @spec cancel_order(map(), map() | nil) :: {:ok, %Binance.Order{}} | {:error, error()}
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
