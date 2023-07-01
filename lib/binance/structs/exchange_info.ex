defmodule Binance.ExchangeInfo do
  @moduledoc """
  Struct for representing the result returned by /api/v1/exchangeInfo
  """

  defstruct [
    :timezone,
    :server_time,
    :rate_limits,
    :exchange_filters,
    :symbols
  ]

  use ExConstructor
end
