# binance.ex

Elixir wrapper for interacting with the [Binance API](https://github.com/binance-exchange/binance-official-api-docs).

## Installation

1. The package can be installed by adding `binance` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:binance, "~> 0.1.0"}
  ]
end
```

2. Add `:binance` to your applications

```
def application do
  [applications: [:binance]]
end
```

3. Add your Binance API credentials to your `config.exs` file, like so (you can create a new API
key [here](https://www.binance.com/userCenter/createApi.html)):

```
config :binance,
  api_key: "xxx",
  secret_key: "xxx"
```

## Usage

Documentation available at [https://hexdocs.pm/binance](https://hexdocs.pm/binance).

Get all prices
```
iex> Binance.get_all_prices
{:ok,
 [%Binance.SymbolPrice{price: "0.07718300", symbol: "ETHBTC"},
  %Binance.SymbolPrice{price: "0.01675400", symbol: "LTCBTC"},
  %Binance.SymbolPrice{price: "0.00114690", symbol: "BNBBTC"},
  %Binance.SymbolPrice{price: "0.00655900", symbol: "NEOBTC"},
  %Binance.SymbolPrice{price: "0.00030000", symbol: "123456"},
  %Binance.SymbolPrice{price: "0.04754000", symbol: "QTUMETH"},
  %Binance.SymbolPrice{price: "0.00778500", symbol: "EOSETH"}
  ...]}
```

Buy 100 REQ for the current market price

```
iex> Binance.order_market_buy("REQETH", 100)
{:ok, %{}}
```

## Trade pair normalization

For convenience, all functions that require a symbol in the form of "ETHBTC" also accept a
`%Binance.TradePair{}` struct in the form of `%Binance.TradePair{from: "ETH", to: "BTC"}`. The order of symbols in `%Binance.TradePair{}` does not matter. All symbols are also case insensitive.

`Binance.find_symbol/1` will return the correct string representation as it is listed on binance

```
Binance.find_symbol(%Binance.TradePair{from: "ReQ", to: "eTH"})
{:ok, "REQETH"}

Binance.find_symbol(%Binance.TradePair{from: "ETH", to: "REQ"})
{:ok, "REQETH"}
```

## WebSocket API

Binance provides a WebSocket API if you want to process events in real time: https://github.com/binance-exchange/binance-official-api-docs/blob/master/web-socket-streams.md#individual-symbol-ticker-streams

If you want to handle events for ticker, use the example below:

```elixir
defmodule MyTickerHandler do
  @behaviour Binance.WebSocket.TickerHandler

  def handle_event(%Binance.WebSocket.TickerEvent{} = event) do
    IO.puts("event: trades=#{event.trades} open_price=#{event.open_price}")
  end
end

Binance.WebSocket.TickerWebSocket.start("neoeth", [handler: MyTickerHandler])
```

## License

MIT
