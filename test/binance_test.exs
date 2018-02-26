defmodule BinanceTest do
  use ExUnit.Case
  doctest Binance

  test "get_server_time returns the server time" do
    {:ok, time} = Binance.get_server_time()
    assert is_number(time)
  end
end
