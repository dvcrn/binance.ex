defmodule Binance.Responses.TickerPrice do
  def new(data) do
    Enum.map(data, &Binance.Structs.SymbolPrice.new(&1))
  end
end
