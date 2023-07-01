defmodule Binance.Ticker do
  @moduledoc """
  Struct for representing a result row as returned by /api/v1/ticker/24hr

  ```
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
  ```
  """

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
