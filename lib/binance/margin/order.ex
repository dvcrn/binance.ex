defmodule Binance.Margin.Order do
  defstruct [
    :symbol,
    :order_id,
    :client_order_id,
    :transact_time,
    :price,
    :orig_qty,
    :executed_qty,
    :cummulative_quote_qty,
    :status,
    :time_in_force,
    :type,
    :side
  ]

  use ExConstructor
end
