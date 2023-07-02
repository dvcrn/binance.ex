defmodule Binance.ResponseMapping do
  @moduledoc false

  # Maps APIs to specific structs
  # The struct needs to have a .new() method that takes the data returned on successful API call by Binance. .new() was chosen as this is used by ExConstructor by default
  # Some APIs return a list of things and not a single struct, the initializers for those are in Binance.Responses.X which then returns a list of Binance.Structs.X

  def lookup(path_key) do
    mappings = %{
      "get:/api/v3/klines" => Binance.Responses.Klines,
      "get:/api/v3/account" => Binance.Structs.Account,
      "get:/api/v3/time" => Binance.Structs.ServerTime,
      "get:/api/v3/historicalTrades" => Binance.Responses.HistoricalTrades,
      "get:/api/v3/depth" => Binance.Structs.OrderBook,
      "post:/api/v3/order" => Binance.Structs.OrderResponse,
      "delete:/api/v3/order" => Binance.Structs.Order,
      "get:/api/v3/openOrders" => Binance.Responses.OpenOrders,
      "get:/sapi/v1/system/status" => Binance.Structs.SystemStatus,
      "get:/api/v3/ticker" => Binance.Structs.Ticker,
      "get:/api/v3/ticker/24hr" => Binance.Structs.Ticker,
      "get:/api/v3/ticker/price" => Binance.Responses.TickerPrice,
      "get:/api/v3/exchangeInfo" => Binance.Structs.ExchangeInfo,
      "post:/api/v3/userDataStream" => Binance.Structs.DataStream
    }

    Map.get(mappings, path_key, nil)
  end
end
