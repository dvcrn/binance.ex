defmodule Binance.Responses.OpenOrders do
  def new(data) do
    Enum.map(data, &Binance.Structs.Order.new(&1))
  end
end
