defmodule Binance.Futures.Order do
  defstruct [
    :client_order_id,
    :cum_qty,
    :cum_quote,
    :executed_qty,
    :order_id,
    :orig_qty,
    :avg_price,
    :price,
    :reduce_only,
    :side,
    :status,
    :stop_price,
    :symbol,
    :time_in_force,
    :type,
    :update_time,
    :time
  ]

  use ExConstructor
end
