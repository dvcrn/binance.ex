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

  defp create_order(
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
      error ->
        error
    end
  end

  def cancel_order(params, order_type, config \\ nil) do
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
