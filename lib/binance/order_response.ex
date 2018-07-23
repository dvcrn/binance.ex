defmodule Binance.OrderResponse do
  @moduledoc """
  Struct for representing the result returned by  GET /api/v3/allOrders, GET /api/v3/openOrders, GET /api/v3/order and POST /api/v3/order
  """

  defstruct [
    :client_order_id,
    :executed_qty,
    :order_id,
    :iceberg_qty,
    :is_working,
    :orig_qty,
    :price,
    :side,
    :status,
    :stop_price,
    :symbol,
    :time,
    :time_in_force,
    :transact_time,
    :type
  ]

  use ExConstructor
end
