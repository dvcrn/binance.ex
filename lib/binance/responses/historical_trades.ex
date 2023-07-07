defmodule Binance.Responses.HistoricalTrades do
  def new(data) do
    Enum.map(data, &Binance.Structs.HistoricalTrade.new(&1))
  end
end
