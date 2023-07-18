defmodule Binance.PortfolioMargin.UMOrder do
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
    :position_side,
    :status,
    :symbol,
    :time_in_force,
    :type,
    :update_time
  ]

  use ExConstructor
end
