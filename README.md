# binance.ex

Elixir wrapper for interacting with the [Binance API](https://github.com/binance/binance-spot-api-docs).

## Installation

1. The package can be installed by adding `binance` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:binance, "~> 1.0"}
  ]
end
```

2. Export your Binance API credentials, like so (you can create a new API
   key [here](https://www.binance.com/en/my/settings/api-management)):

```
export BINANCE_API_KEY=****************************************************************
export BINANCE_SECRET_KEY==************************************************************
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

## License

MIT
