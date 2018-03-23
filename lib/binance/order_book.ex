defmodule Binance.OrderBook do
  @moduledoc """
  Struct for representing the result returned by /api/v1/depth
  """

  defstruct [:bids, :asks, :last_update_id]

  use ExConstructor
end
