defmodule FuturesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    System.put_env("BINANCE_API_KEY", "fake_api_key")
    System.put_env("BINANCE_API_SECRET", "fake_secret_key")
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
        assert Binance.Futures.create_listen_key(%{}) == {
                 :ok,
                 %{
                   "listenKey" =>
                     "SHKiq1MSr119hfs4ZB6EZWkdikAPq8RGVuQGdGMnvvUUmaeZygVcoO1CchfzXeCd"
                 },
                 %{}
               }
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "futures/keep_alive_listen_key_ok" do
        assert Binance.Futures.keep_alive_listen_key(%{}) == {:ok, ""}
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
        assert Binance.get_depth("IDONTEXIST", 1000) ==
                 {:error, {:binance_error, %{code: -1121, msg: "Invalid symbol."}}}
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

  describe ".get_position" do
    test "returns current position information" do
      use_cassette "futures/get_position_ok" do
        assert Binance.Futures.get_position() ==
                 {:ok,
                  [
                    %Binance.Futures.Position{
                      entry_price: "6901.58000",
                      leverage: "20",
                      liquidation_price: "0",
                      max_notional_value: "5000000",
                      position_amt: "0.001",
                      symbol: "BTCUSDT",
                      mark_price: "7519.01708334",
                      unRealized_profit: "0.61743708"
                    },
                    %Binance.Futures.Position{
                      entry_price: "0.00000",
                      leverage: "20",
                      liquidation_price: "0",
                      max_notional_value: "250000",
                      position_amt: "0.000",
                      symbol: "ETHUSDT",
                      unRealized_profit: "0.00000000",
                      mark_price: "153.04898463"
                    }
                  ]}
      end
    end
  end

  describe ".create_order limit buy" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "futures/order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.Futures.Order{} = response,
                %{used_order_limit: "1", used_weight_limit: "0"}} =
                 Binance.Futures.create_order(%{
                   symbol: "BTCUSDT",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 8000,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "e7BFySSxfObXahpsHJirjC"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 2_634_722_102
        assert response.orig_qty == "0.001"
        assert response.price == "8000"
        assert response.reduce_only == false
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.time == nil
        assert response.update_time == 1_586_855_766_315
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "futures/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason, rate_limit} =
                 Binance.Futures.create_order(%{
                   symbol: "BTCUSDT",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.05,
                   price: 9000,
                   time_in_force: "GTC"
                 })

        # Binance.Futures.create_order("BTCUSDT", "BUY", "LIMIT", 0.05, 9000)

        assert reason ==
                 {:binance_error,
                  %{
                    code: -1000,
                    msg: "You don't have enough margin for this new order"
                  }}

        assert rate_limit = %{}
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "futures/order_limit_sell_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.Futures.Order{} = response, %{}} =
                 Binance.Futures.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 11000,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "VV0vLLVnABzLXwYxvDkYqF"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 10_800_687
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_976_216_827
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "futures/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason, rate_limit} =
                 Binance.Futures.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.05,
                   price: 11000,
                   time_in_force: "GTC"
                 })

        assert reason ==
                 {:binance_error,
                  %{
                    code: -1000,
                    msg: "You don't have enough margin for this new order"
                  }}

        assert rate_limit == %{}
      end
    end
  end

  describe ".get_open_orders" do
    test "when called without symbol returns all open orders for all symbols" do
      use_cassette "futures/get_open_orders_without_symbol_success" do
        assert {:ok,
                [
                  %Binance.Futures.Order{} = order_1,
                  %Binance.Futures.Order{} = order_2
                ]} = Binance.Futures.get_open_orders()

        assert order_1.client_order_id == "web_argH9snTII2DpZQ1lkzD"
        assert order_1.cum_quote == "0"
        assert order_1.executed_qty == "0"
        assert order_1.order_id == 2_634_617_095
        assert order_1.orig_qty == "0.001"
        assert order_1.price == "9000"
        assert order_1.reduce_only == false
        assert order_1.side == "SELL"
        assert order_1.status == "NEW"
        assert order_1.stop_price == "0"
        assert order_1.symbol == "BTCUSDT"
        assert order_1.time_in_force == "GTC"
        assert order_1.type == "LIMIT"
        assert order_1.update_time == 1_586_855_589_773
        assert order_1.time == 1_586_855_389_188

        assert order_2.client_order_id == "web_zyRe8mQWmV2GOoLxdSYr"
        assert order_2.cum_quote == "0"
        assert order_2.executed_qty == "0"
        assert order_2.order_id == 2_634_612_040
        assert order_2.orig_qty == "0.001"
        assert order_2.price == "8786.98"
        assert order_2.reduce_only == false
        assert order_2.side == "SELL"
        assert order_2.status == "NEW"
        assert order_2.stop_price == "0"
        assert order_2.symbol == "BTCUSDT"
        assert order_2.time_in_force == "GTC"
        assert order_2.type == "LIMIT"
        assert order_2.update_time == 1_586_855_589_773
        assert order_2.time == 1_586_855_377_085
      end
    end

    test "when called with symbol returns all open orders for that symbols(string)" do
      use_cassette "futures/get_open_orders_with_symbol_string_success" do
        assert {:ok, [%Binance.Futures.Order{} = order_1]} =
                 Binance.Futures.get_open_orders(%{symbol: "BTCUSDT"})

        assert order_1.client_order_id == "kFVoo0nClhOku6KbcB8B1X"
        assert order_1.cum_quote == "0"
        assert order_1.executed_qty == "0"
        assert order_1.order_id == 11_333_637
        assert order_1.orig_qty == "0.001"
        assert order_1.price == "11000"
        assert order_1.reduce_only == false
        assert order_1.side == "SELL"
        assert order_1.status == "NEW"
        assert order_1.stop_price == "0"
        assert order_1.symbol == "BTCUSDT"
        assert order_1.time_in_force == "GTC"
        assert order_1.type == "LIMIT"
        assert order_1.update_time == 1_568_995_541_781
      end
    end
  end

  describe ".get_order" do
    test "gets an order information by exchange order id" do
      use_cassette "futures/get_order_by_exchange_order_id_ok" do
        assert {:ok, %Binance.Futures.Order{} = response} =
                 Binance.Futures.get_order(%{symbol: "BTCUSDT", order_id: 10_926_974})

        assert response.client_order_id == "F1YDd19xJvGWNiBbt7JCrr"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 10_926_974
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_988_806_336
      end
    end

    test "gets an order information by client order id" do
      use_cassette "futures/get_order_by_client_order_id_ok" do
        assert {:ok, %Binance.Futures.Order{} = response} =
                 Binance.Futures.get_order(%{
                   symbol: "BTCUSDT",
                   orig_client_order_id: "F1YDd11xJvGWNiBbt7JCrr"
                 })

        assert response.client_order_id == "F1YDd19xJvGWNiBbt7JCrr"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 10_926_974
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_988_806_336
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "futures/get_order_error" do
        assert Binance.Futures.get_order(%{symbol: "BTCUSDT", order_id: 123_456_789}) ==
                 {:error, {:binance_error, %{code: -2013, msg: "Order does not exist."}}}
      end
    end
  end

  describe ".cancel_order" do
    test "cancel an order by exchange order id" do
      use_cassette "futures/cancel_order_by_exchange_order_id_ok" do
        assert {:ok, %Binance.Futures.Order{} = response, %{}} =
                 Binance.Futures.cancel_order(%{symbol: "BTCUSDT", order_id: 11_257_530})

        assert response.client_order_id == "wgQyWAlBFCCWinOy7yPFDu"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 11_222_530
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "CANCELED"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_999_338_577
      end
    end

    test "cancel an order by client order id" do
      use_cassette "futures/cancel_order_by_client_order_id_ok" do
        assert {:ok, %Binance.Futures.Order{} = response, %{}} =
                 Binance.Futures.cancel_order(%{
                   symbol: "BTCUSDT",
                   orig_client_order_id: "Slo0A5UDDOWK7cdUNVUsfO"
                 })

        assert response.client_order_id == "Slo0A5UDDOWK7cdUNVUsfO"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 11_277_192
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "CANCELED"
        assert response.stop_price == "0"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_996_656_841
      end
    end

    test "return errors when cancel an non-existing order" do
      use_cassette "futures/cancel_non_existing_order" do
        assert {:error,
                %{
                  "reduceOnly" => false,
                  "rejectReason" => "UNKNOWN_ORDER",
                  "status" => "REJECTED",
                  "updateTime" => 1_568_995_698_674_402_579
                }, %{}} = Binance.Futures.cancel_order(%{symbol: "BTCUSDT", order_id: 123_456})
      end
    end

    test "cancel batch order by exchange order id" do
      use_cassette "futures/cancel_batch_order_by_exchange_order_id_ok" do
        assert {:ok, [order1, order2], %{used_weight_limit: "1"}} =
                 Binance.Futures.cancel_batch_order(%{
                   symbol: "BTCUSDT",
                   order_id_list: [1_853_071_596, 1_853_071_597]
                 })

        assert order1["orderId"] == 1_853_071_596
        assert order1["status"] == "CANCELED"
        assert order2["orderId"] == 1_853_071_597
        assert order2["status"] == "CANCELED"
      end
    end

    test "should cancel all open orders by symbol" do
      use_cassette "futures/cancel_all_orders_by_symbol" do
        {:ok, response, %{used_weight_limit: "1"}} =
          Binance.Futures.cancel_all_orders(%{symbol: "BTCUSDT"})

        assert response == %{
                 "code" => 200,
                 "msg" => "The operation of cancel all open order is done."
               }
      end
    end

    test "should return error when cancel all open orders without sending symbol param" do
      use_cassette "futures/cancel_all_orders_by_symbol_error" do
        {:error, response, %{used_weight_limit: "1"}} = Binance.Futures.cancel_all_orders(%{})

        assert response ==
                 {:binance_error,
                  %{
                    code: -1102,
                    msg:
                      "Mandatory parameter 'symbol' was not sent, was empty/null, or malformed."
                  }}
      end
    end
  end

  describe "get" do
    test "best ticker" do
      use_cassette "futures/get_best_ticker" do
        assert Binance.Margin.get_best_ticker("BTCUSDT") ==
                 {:ok,
                  %{
                    "symbol" => "BTCUSDT",
                    "askPrice" => "9043.75000000",
                    "askQty" => "0.46000000",
                    "bidPrice" => "9043.50000000",
                    "bidQty" => "0.48752700"
                  }}
      end
    end

    test "mark price" do
      use_cassette "futures/get_index_price" do
        assert Binance.Futures.get_index_price("BTCUSDT") ==
                 {:ok,
                  %{
                    "symbol" => "BTCUSDT",
                    "lastFundingRate" => "0.00010000",
                    "markPrice" => "9231.61824624",
                    "nextFundingTime" => 1_594_800_000_000,
                    "time" => 1_594_799_650_000
                  }}
      end
    end
  end
end
