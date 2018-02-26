defmodule Binance.WebSocket.TickerHandler do
  @callback handle_event(%Binance.WebSocket.TickerEvent{}) :: any
end
