defmodule Binance.Futures.Position do
  defstruct [
    :entry_price,
    :leverage,
    :max_notional_value,
    :liquidation_price,
    :mark_price,
    :position_amt,
    :symbol,
    :unRealized_profit
  ]

  use ExConstructor
end
