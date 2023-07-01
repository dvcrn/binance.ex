defmodule Binance.ResponseMapping do
  @moduledoc false

  def lookup(path_key) do
    mappings = %{
      "get:/api/v3/klines" => Binance.Structs.Kline,
      "get:/api/v3/account" => Binance.Structs.Account,
      "get:/api/v3/time" => Binance.Structs.ServerTime,
      "get:/api/v3/historicalTrades" => Binance.Structs.HistoricalTrade
    }

    Map.get(mappings, path_key, nil)
  end
end
