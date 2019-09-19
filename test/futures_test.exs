defmodule FuturesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  test "ping returns an empty map" do
    use_cassette "futures/ping_ok" do
      assert Binance.Futures.ping() == {:ok, %{}}
    end
  end

  test "get_server_time success return an ok, time tuple" do
    use_cassette "futures/get_server_time_ok" do
      assert Binance.Futures.get_server_time() == {:ok, 1_568_879_218_176}
    end
  end

  test "get_exchange_info success returns the trading rules and symbol information" do
    use_cassette "futures/get_exchange_info_ok" do
      assert {:ok, %Binance.ExchangeInfo{} = info} = Binance.Futures.get_exchange_info()
      assert info.timezone == "UTC"
      assert info.server_time != nil

      assert info.rate_limits == [
               %{
                 "interval" => "MINUTE",
                 "limit" => 1200,
                 "rateLimitType" => "REQUEST_WEIGHT",
                 "intervalNum" => 1
               },
               %{
                 "interval" => "MINUTE",
                 "intervalNum" => 1,
                 "limit" => 600,
                 "rateLimitType" => "ORDERS"
               }
             ]

      assert info.exchange_filters == []
      assert [symbol | _] = info.symbols

      assert symbol == %{
               "baseAsset" => "BTC",
               "baseAssetPrecision" => 8,
               "filters" => [
                 %{
                   "filterType" => "PRICE_FILTER",
                   "maxPrice" => "100000",
                   "minPrice" => "0.01",
                   "tickSize" => "0.01"
                 },
                 %{
                   "filterType" => "LOT_SIZE",
                   "maxQty" => "1000",
                   "minQty" => "0.001",
                   "stepSize" => "0.001"
                 },
                 %{
                   "filterType" => "MARKET_LOT_SIZE",
                   "maxQty" => "1000",
                   "minQty" => "0.001",
                   "stepSize" => "0.001"
                 },
                 %{"filterType" => "MAX_NUM_ORDERS", "limit" => 0},
                 %{
                   "filterType" => "PERCENT_PRICE",
                   "multiplierDecimal" => "4",
                   "multiplierDown" => "0.8500",
                   "multiplierUp" => "1.1500"
                 }
               ],
               "maintMarginPercent" => "2.5000",
               "orderTypes" => ["LIMIT", "MARKET", "STOP"],
               "pricePrecision" => 2,
               "quantityPrecision" => 3,
               "quoteAsset" => "USDT",
               "quotePrecision" => 8,
               "requiredMarginPercent" => "5.0000",
               "status" => "TRADING",
               "symbol" => "BTCUSDT",
               "timeInForce" => ["GTC", "IOC", "FOK", "GTX"]
             }
    end
  end

  describe ".create_listen_key" do
    test "returns a listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "futures/create_listen_key_ok" do
        assert Binance.Futures.create_listen_key() == {
                 :ok,
                 %{
                   "listenKey" =>
                     "SHKiq1MSr119hfs4ZB6EZWkdikAPq8RGVuQGdGMnvvUUmaeZygVcoO1CchfzXeCd"
                 }
               }
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "futures/keep_alive_listen_key_ok" do
        assert Binance.Futures.keep_alive_listen_key() == {:ok, ""}
      end
    end
  end

  describe ".get_depth" do
    test "returns the bids & asks up to the given depth" do
      use_cassette "futures/get_depth_ok" do
        assert Binance.Futures.get_depth("BTCUSDT", 5) == {
                 :ok,
                 %Binance.OrderBook{
                   asks: [
                     ["9876.71", "2.569"],
                     ["9877.08", "1.745"],
                     ["9877.48", "1.743"],
                     ["9878.15", "1.580"],
                     ["9878.36", "3.091"]
                   ],
                   bids: [
                     ["9875.74", "1.849"],
                     ["9875.59", "2.752"],
                     ["9875.16", "2.588"],
                     ["9874.67", "1.547"],
                     ["9873.80", "3.647"]
                   ],
                   last_update_id: 36_154_698
                 }
               }
      end
    end

    test "returns an error tuple when the symbol doesn't exist" do
      use_cassette "get_depth_error" do
        assert Binance.get_depth("IDONTEXIST", 1000) == {
                 :error,
                 %{"code" => -1121, "msg" => "Invalid symbol."}
               }
      end
    end
  end

  describe ".get_account" do
    test "returns current account information" do
      use_cassette "futures/get_account_ok" do
        assert Binance.Futures.get_account() == {
                 :ok,
                 %Binance.Futures.Account{
                   assets: [
                     %{
                       "asset" => "USDT",
                       "initialMargin" => "0.00000000",
                       "maintMargin" => "0.00000000",
                       "marginBalance" => "10.18000000",
                       "unrealizedProfit" => "0.00000000",
                       "walletBalance" => "10.18000000"
                     }
                   ],
                   can_deposit: true,
                   can_trade: true,
                   can_withdraw: true,
                   fee_tier: 0,
                   total_initial_margin: "0.00000000",
                   total_maint_margin: "0.00000000",
                   total_margin_balance: "10.18000000",
                   total_unrealized_profit: "0.00000000",
                   total_wallet_balance: "10.18000000",
                   update_time: 0
                 }
               }
      end
    end
  end
end
