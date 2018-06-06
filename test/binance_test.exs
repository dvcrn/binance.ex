defmodule BinanceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  test "ping returns an empty map" do
    use_cassette "ping_ok" do
      assert Binance.ping() == {:ok, %{}}
    end
  end

  test "get_server_time success return an ok, time tuple" do
    use_cassette "get_server_time_ok" do
      assert Binance.get_server_time() == {:ok, 1_521_781_361_467}
    end
  end

  test "get_all_prices returns a list of prices for every symbol" do
    use_cassette "get_all_prices_ok" do
      assert {:ok, symbol_prices} = Binance.get_all_prices()
      assert [%Binance.SymbolPrice{price: "0.06137000", symbol: "ETHBTC"} | _tail] = symbol_prices
      assert symbol_prices |> Enum.count() == 288
    end
  end

  test "get_ticker returns a ticker struct with details for the given symbol" do
    use_cassette "get_ticker_ok" do
      assert {
               :ok,
               %Binance.Ticker{
                 ask_price: "0.01876000",
                 bid_price: "0.01875200",
                 close_time: 1_521_826_338_547,
                 count: 30612
               }
             } = Binance.get_ticker("LTCBTC")
    end
  end

  test "get_ticker returns an error tuple when the symbol doesn't exist" do
    use_cassette "get_ticker_error" do
      assert Binance.get_ticker("IDONTEXIST") == {
               :error,
               %{"code" => -1121, "msg" => "Invalid symbol."}
             }
    end
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
                 last_update_id: 113_634_395
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
