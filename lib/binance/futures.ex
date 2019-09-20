defmodule Binance.Futures do
  alias Binance.Futures.Rest.HTTPClient

  # Server

  @doc """
  Pings Binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  def ping() do
    HTTPClient.get_binance("/fapi/v1/ping")
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
    case HTTPClient.get_binance("/fapi/v1/time") do
      {:ok, %{"serverTime" => time}} -> {:ok, time}
      err -> err
    end
  end

  def get_exchange_info() do
    case HTTPClient.get_binance("/fapi/v1/exchangeInfo") do
      {:ok, data} -> {:ok, Binance.ExchangeInfo.new(data)}
      err -> err
    end
  end

  def create_listen_key(
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

    arguments = %{
      timestamp: timestamp,
      recvWindow: receiving_window
    }

    case HTTPClient.post_binance("/fapi/v1/listenKey", arguments) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  def keep_alive_listen_key(receiving_window \\ 1000, timestamp \\ nil) do
    timestamp =
      case timestamp do
        # timestamp needs to be in milliseconds
        nil ->
          :os.system_time(:millisecond)

        t ->
          t
      end

    arguments = %{
      timestamp: timestamp,
      recvWindow: receiving_window
    }

    case HTTPClient.put_binance("/fapi/v1/listenKey", arguments) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
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
    case HTTPClient.get_binance("/fapi/v1/depth?symbol=#{symbol}&limit=#{limit}") do
      {:ok, data} -> {:ok, Binance.OrderBook.new(data)}
      err -> err
    end
  end

  # Account

  @doc """
  Fetches user account from binance

  Returns `{:ok, %Binance.Account{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/
  """

  def get_account() do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    case HTTPClient.get_binance("/fapi/v1/account", %{}, secret_key, api_key) do
      {:ok, data} ->
        {:ok, Binance.Futures.Account.new(data)}

      error ->
        error
    end
  end

  # Order

  @doc """
  Creates a new order on Binance Futures

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on Binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#new-order-trade
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
      |> Map.merge(unless(is_nil(stop_price), do: %{stopPrice: stop_price}, else: %{}))
      |> Map.merge(unless(is_nil(time_in_force), do: %{timeInForce: time_in_force}, else: %{}))
      |> Map.merge(unless(is_nil(price), do: %{price: price}, else: %{}))

    case HTTPClient.post_binance("/fapi/v1/order", arguments) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  @doc """
  Creates a new **limit** **buy** order

  Symbol can be a binance symbol in the form of `"BTCUSDT"`

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_buy(symbol, quantity, price, time_in_force \\ "GTC")
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "BUY", "LIMIT", quantity, price, time_in_force)
    |> parse_order_response
  end

  @doc """
  Creates a new **limit** **sell** order

  Symbol can be a binance symbol in the form of `"BTCUSDT"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_sell(symbol, quantity, price, time_in_force \\ "GTC")
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    create_order(symbol, "SELL", "LIMIT", quantity, price, time_in_force)
    |> parse_order_response
  end

  @doc """
  Get order by symbol and either orderId or origClientOrderId are mandatory

  Returns `{:ok, [%Binance.Futures.OrderResponse{}]}` or `{:error, reason}`.

  Weight: 1

  ## Example
  ```
  {:ok, %Binance.Futures.OrderResponse{price: "0.1", origQty: "1.0", executedQty: "0.0", ...}}
  ```

  Info: https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#query-order-user_data
  """
  def get_order(
        symbol,
        order_id \\ nil,
        orig_client_order_id \\ nil
      )
      when is_binary(symbol)
      when is_integer(order_id) or is_binary(orig_client_order_id) do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    arguments =
      %{
        symbol: symbol
      }
      |> Map.merge(unless(is_nil(order_id), do: %{orderId: order_id}, else: %{}))
      |> Map.merge(
        unless(
          is_nil(orig_client_order_id),
          do: %{origClientOrderId: orig_client_order_id},
          else: %{}
        )
      )

    case HTTPClient.get_binance("/fapi/v1/order", arguments, secret_key, api_key) do
      {:ok, data} -> {:ok, Binance.Futures.OrderResponse.new(data)}
      err -> err
    end
  end

  @doc """
  Cancel an active order.

  Symbol and either orderId or origClientOrderId must be sent.

  Returns `{:ok, %Binance.Futures.OrderResponse{}}` or `{:error, reason}`.

  Weight: 1

  Info: https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#cancel-order-trade
  """
  def cancel_order(
        symbol,
        order_id \\ nil,
        orig_client_order_id \\ nil
      )
      when is_binary(symbol)
      when is_integer(order_id) or is_binary(orig_client_order_id) do
    api_key = Application.get_env(:binance, :api_key)
    secret_key = Application.get_env(:binance, :secret_key)

    arguments =
      %{
        symbol: symbol
      }
      |> Map.merge(unless(is_nil(order_id), do: %{orderId: order_id}, else: %{}))
      |> Map.merge(
        unless(
          is_nil(orig_client_order_id),
          do: %{origClientOrderId: orig_client_order_id},
          else: %{}
        )
      )

    case HTTPClient.delete_binance("/fapi/v1/order", arguments, secret_key, api_key) do
      {:ok, %{"rejectReason" => _} = err} -> {:error, err}
      {:ok, data} -> {:ok, Binance.Futures.OrderResponse.new(data)}
      err -> err
    end
  end

  defp parse_order_response({:ok, response}) do
    {:ok, Binance.Futures.OrderResponse.new(response)}
  end

  defp parse_order_response({
         :error,
         {
           :binance_error,
           %{code: -1000, msg: "You don't have enough margin for this new order"} = reason
         }
       }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
  end
end
