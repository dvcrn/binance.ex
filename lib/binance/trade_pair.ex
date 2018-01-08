defmodule Binance.TradePair do
  @moduledoc """
  Struct for representing a normalized trade pair.

  ```
  @enforce_keys [:from, :to]
  defstruct @enforce_keys
  ```
  """

  @enforce_keys [:from, :to]
  defstruct @enforce_keys
end
