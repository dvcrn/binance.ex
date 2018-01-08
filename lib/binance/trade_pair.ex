defmodule Binance.TradePair do
  @enforce_keys [:from, :to]
  defstruct @enforce_keys
end
