defmodule Binance.Margin do
  alias Binance.Margin.Rest.HTTPClient

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  def create_listen_key(config \\ nil) do
    case HTTPClient.post_binance("/sapi/v1/userDataStream", %{}, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  def create_isolated_listen_key(symbol, config \\ nil) do
    case HTTPClient.post_binance(
           "/sapi/v1/userDataStream/isolated",
           %{symbol: symbol},
           config,
           false
         ) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  def keep_alive_listen_key(listen_key, config \\ nil) do
    arguments = %{
      listenKey: listen_key
    }

    case HTTPClient.put_binance("/sapi/v1/userDataStream", arguments, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  def keep_alive_isolated_listen_key(symbol, listen_key, config \\ nil) do
    arguments = %{
      symbol: symbol,
      listenKey: listen_key
    }

    case HTTPClient.put_binance("/sapi/v1/userDataStream/isolated", arguments, config, false) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  def get_account(config \\ nil) do
    case HTTPClient.get_binance("/sapi/v1/margin/account", %{}, config) do
      {:ok, data} ->
        {:ok, Binance.Margin.Account.new(data)}

      error ->
        error
    end
  end

  def get_index_price(instrument, config \\ nil) do
    case HTTPClient.get_binance("/sapi/v1/margin/priceIndex", %{symbol: instrument}, config) do
      {:ok, data} -> {:ok, data}
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
          is_nil(params[:time_in_force]),
          do: %{timeInForce: params[:time_in_force]},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(params[:price]), do: %{price: params[:price]}, else: %{}))
      |> Map.merge(
        unless(
          is_nil(params[:side_effect_type]),
          do: %{sideEffectType: params[:side_effect_type]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:is_isolated]), do: %{isIsolated: params[:is_isolated]}, else: %{})
      )

    case HTTPClient.post_binance("/sapi/v1/margin/order", arguments, config) do
      {:ok, data} ->
        {:ok, Binance.Margin.Order.new(data)}

      error ->
        error
    end
  end

  def cancel_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol]
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

    case HTTPClient.delete_binance("/sapi/v1/margin/order", arguments, config) do
      {:ok, %{"rejectReason" => _} = err} -> {:error, err}
      {:ok, data} -> {:ok, Binance.Margin.Order.new(data)}
      err -> err
    end
  end

  @doc """
  https://binance-docs.github.io/apidocs/spot/en/#margin-account-borrow-margin

  is_isolated: can be either "TRUE" or "FALSE". If "TRUE", symbol must be present.
  symbol: instrument like BTCUSDT, etc
  asset: currency like USDT or BTC, etc
  amount: how many tokens to borrow

  """
  def borrow(params, config \\ nil) do
    arguments =
      %{
        asset: params[:asset],
        amount: params[:amount],
        timestamp: params[:timestamp] || :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:is_isolated]), do: %{isIsolated: params[:is_isolated]}, else: %{})
      )
      |> Map.merge(unless(is_nil(params[:symbol]), do: %{symbol: params[:symbol]}, else: %{}))
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    HTTPClient.post_binance("/sapi/v1/margin/loan", arguments, config)
  end
end
