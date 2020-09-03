# binance.ex

[![Build Status](https://travis-ci.org/dvcrn/binance.ex.svg?branch=master)](https://travis-ci.org/dvcrn/binance.ex)

Elixir wrapper for interacting with the [Binance API](https://github.com/binance-exchange/binance-official-api-docs).

## Installation

1. The package can be installed by adding `binance` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:binance, "~> 0.8.0", github: "acuityinnovations/binance.ex", branch: "master"}
  ]
end
```

2. Add `:binance` to your applications

```
def application do
  [applications: [:binance]]
end
```

## Usage

Documentation to be updated.

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

Binance API credentials could be passed to some APIs calls which require authentication/request signing like so:

```
config = %{access_keys: ["XXX_BINANCE_API_KEY", "XXX_BINANCE_SECRET_KEY"]}
Binance.get_account(config)

# or

Binance.Futures.create_order(%{symbol: "BTCUSDT", side: "SELL", type: "LIMIT", quantity: 0.005, price: 9000, time_in_force: "GTC"}, config)
```

in which, `XXX_BINANCE_API_KEY` and `XXX_BINANCE_SECRET_KEY` are ENV names that holds the values of your API and Secret keys respectively.

## License

MIT
