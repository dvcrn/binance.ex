defmodule Binance.Responses.Klines do
  def new(data) do
    Enum.map(data, &Binance.Structs.Kline.new/1)
  end
end
