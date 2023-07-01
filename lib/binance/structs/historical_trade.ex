defmodule Binance.HistoricalTrade do
  @moduledoc """
  Struct for representing the result returned by /api/v3/historicalTrades
  """

  defstruct [
    :id,
    :price,
    :qty,
    :quote_qty,
    :time,
    :is_buyer_maker,
    :is_best_match
  ]

  use ExConstructor
end
