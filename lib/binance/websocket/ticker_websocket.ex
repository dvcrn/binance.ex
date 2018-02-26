defmodule Binance.WebSocket.TickerWebSocket do
  use WebSockex

  def start(symbol, state) do
    url = "wss://stream.binance.com:9443/ws/#{symbol}@ticker"
    WebSockex.start_link(url, __MODULE__, state)
  end

  def handle_frame({_, msg}, state) do
    {:ok, raw_event} = Poison.decode(msg)

    %Binance.WebSocket.TickerEvent{
      trades: raw_event["n"],
      symbol: raw_event["s"],
      open_price: raw_event["o"]
    }
    |> Keyword.get(state, :handler).handle_event

    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    {:reply, frame, state}
  end
end
