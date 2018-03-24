defmodule BinanceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    HTTPoison.start
  end

  test "get_depth returns the bids & asks up to the given depth" do
    use_cassette "get_depth_ok" do
      assert Binance.get_depth("BTCUSDT", 5) == {
        :ok,
        %Binance.OrderBook{
          asks: [
            ["8400.00000000", "2.04078100", []],
            ["8405.35000000", "0.50354700", []],
            ["8406.00000000", "0.32769800", []],
            ["8406.33000000", "0.00239000", []],
            ["8406.51000000", "0.03241000", []]
          ],
          bids: [
            ["8393.00000000", "0.20453200", []],
            ["8392.57000000", "0.02639000", []],
            ["8392.00000000", "1.40893300", []],
            ["8390.09000000", "0.07047100", []],
            ["8388.72000000", "0.04577400", []]
          ],
          last_update_id: 113634395
        }
      }
    end
  end

  test "get_depth returns an error tuple when the symbol doesn't exist" do
    use_cassette "get_depth_error" do
      assert Binance.get_depth("IDONTEXIST", 1000) == {
        :error,
        %{"code" => -1121, "msg" => "Invalid symbol."}
      }
    end
  end
end
