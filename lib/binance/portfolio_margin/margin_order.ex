defmodule Binance.PortfolioMargin.MarginOrder do
  defstruct [
    :symbol,
    :order_id,
    :transact_time,
    :update_time,
    :price,
    :orig_qty,
    :executed_qty,
    :client_order_id,
    :cummulative_quote_qty,
    :side,
    :status,
    :margin_buy_borrow_amount,
    :margin_buy_borrow_asset,
    :fills,
    :time_in_force,
    :type
  ]

  use ExConstructor
end
