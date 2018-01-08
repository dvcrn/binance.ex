defmodule Binance.Ticker do
  defstruct [
    :price_change,
    :price_change_percent,
    :weighted_avg_price,
    :prev_close_price,
    :last_price,
    :bid_price,
    :ask_price,
    :open_price,
    :high_price,
    :low_price,
    :volume,
    :open_time,
    :close_time,
    :first_id,
    :last_id,
    :count
  ]

  use ExConstructor
end
