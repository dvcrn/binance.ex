defmodule Binance.Structs.Orders do
  def new(data) do
    Enum.map(data, &Binance.Structs.OrderResponse.new(&1))
  end
end
