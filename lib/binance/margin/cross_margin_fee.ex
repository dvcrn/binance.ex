defmodule Binance.Margin.CrossMarginFee do
  @moduledoc """
  Struct for representing a result row as returned by /sapi/v1/margin/crossMarginData
  """

  defstruct [
    :vip_level,
    :coin,
    :borrowable,
    :daily_interest,
    :yearly_interest,
    :borrow_limit,
    :marginable_pairs
  ]

  use ExConstructor
end
