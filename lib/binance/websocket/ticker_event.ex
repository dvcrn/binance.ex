defmodule Binance.WebSocket.TickerEvent do
  @moduledoc """
  Struct for representing an event as returned by https://github.com/binance-exchange/binance-official-api-docs/blob/master/web-socket-streams.md#individual-symbol-ticker-streams
  """

  defstruct [
    :symbol,
    :open_price,
    :high_price,
    :trades
  ]

  use ExConstructor
end
