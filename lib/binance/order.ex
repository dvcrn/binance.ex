defmodule Binance.Order do
  @moduledoc """
  Struct for representing the result returned by /api/v3/openOrders
  """

  defstruct [
    :symbol,
    :order_id,
    :client_order_id,
    :avg_price,
    :price,
    :orig_qty,
    :executed_qty,
    :cummulative_quote_qty,
    :status,
    :time_in_force,
    :type,
    :side,
    :stop_price,
    :iceberg_qty,
    :time,
    :update_time,
    :is_working
  ]

  use ExConstructor
end
