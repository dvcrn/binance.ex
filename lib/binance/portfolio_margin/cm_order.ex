defmodule Binance.PortfolioMargin.CMOrder do
  defstruct [
    :client_order_id,
    :cum_qty,
    :cum_base,
    :executed_qty,
    :order_id,
    :orig_qty,
    :avg_price,
    :price,
    :reduce_only,
    :side,
    :position_side,
    :status,
    :symbol,
    :pair,
    :time_in_force,
    :type,
    :update_time
  ]

  use ExConstructor
end
