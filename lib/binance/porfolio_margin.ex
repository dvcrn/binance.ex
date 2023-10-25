defmodule Binance.PortfolioMargin do
  @moduledoc false
  alias Binance.Rest.HTTPClient

  @endpoint "https://papi.binance.com"

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  # Server

  @doc """
  Pings Binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  @spec ping() :: {:ok, %{}, any()} | {:error, error()}
  def ping() do
    HTTPClient.get_binance("#{@endpoint}/papi/v1/ping")
  end

  def create_listen_key(params, config \\ nil) do
    arguments =
      %{
        timestamp: :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:timestamp]), do: %{timestamp: params[:timestamp]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    case HTTPClient.post_binance("#{@endpoint}/papi/v1/listenKey", arguments, config) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def create_order(
        %{symbol: symbol, side: side, type: type, quantity: quantity} = params,
        order_type,
        config \\ nil,
        options \\ []
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
        unless(is_nil(params[:reduce_only]), do: %{reduceOnly: params[:reduce_only]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:stop_price]), do: %{stopPrice: params[:stop_price]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:quote_order_qty]), do: %{quoteOrderQty: params[:quote_order_qty]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:iceberg_qty]), do: %{icebergQty: params[:iceberg_qty]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:side_effect_type]), do: %{sideEffectType: params[:side_effect_type]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:new_order_resp_type]), do: %{newOrderRespType: params[:new_order_resp_type]}, else: %{})
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

    case HTTPClient.post_binance("#{@endpoint}/papi/v1/#{order_type}/order", arguments, config, true, options) do
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Binance.PortfolioMargin.MarginOrder.new(data), headers}
      error ->
        error
    end
  end

  def get_open_orders(order_type, params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/papi/v1/#{order_type}/openOrders", params, config) do
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Enum.map(data, &Binance.PortfolioMargin.UMOrder.new(&1)), headers}
      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Enum.map(data, &Binance.PortfolioMargin.CMOrder.new(&1)), headers}
      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Enum.map(data, &Binance.PortfolioMargin.MarginOrder.new(&1)), headers}
      err -> err
    end
  end

  def get_order(order_type, params, config \\ nil) do
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

    case HTTPClient.get_binance("#{@endpoint}/papi/v1/#{order_type}/order", arguments, config) do
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Binance.PortfolioMargin.MarginOrder.new(data), headers}
      err -> err
    end
  end

  def cancel_order(order_type, params, config \\ nil) do
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

    case HTTPClient.delete_binance("#{@endpoint}/papi/v1/#{order_type}/order", arguments, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}
      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Binance.PortfolioMargin.MarginOrder.new(data), headers}
      err -> err
    end
  end

  def cancel_all_orders(params, order_type, config \\ nil) do
    case HTTPClient.delete_binance("#{@endpoint}/papi/v1/#{order_type}/allOpenOrders", params, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

end
