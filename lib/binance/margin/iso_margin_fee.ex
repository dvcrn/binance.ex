defmodule Binance.Margin.IsoMarginFee do
  @moduledoc """
  Struct for representing a result row as returned by /sapi/v1/margin/isolatedMarginData
  """

  defstruct [
    :vip_level,
    :symbol,
    :leverage,
    :data
  ]

  use ExConstructor
end
