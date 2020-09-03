defmodule CoinTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # setup_all do
  #   System.put_env("BINANCE_API_KEY", "fake_api_key")
  #   System.put_env("BINANCE_API_SECRET", "fake_secret_key")
  #   HTTPoison.start()
  # end

  test "ping returns an empty map" do
    use_cassette "coin/ping_ok" do
      assert Binance.FuturesCoin.ping() == {:ok, %{}}
    end
  end

  test "get_server_time success return an ok, time tuple" do
    use_cassette "coin/get_server_time_ok" do
      assert Binance.FuturesCoin.get_server_time() == {:ok, 1_597_745_352_553}
    end
  end

  test "get_exchange_info success returns the trading rules and symbol information" do
    use_cassette "coin/get_exchange_info_ok" do
      assert {:ok, info} = Binance.FuturesCoin.get_exchange_info()
      assert info.timezone == "UTC"
      assert info.server_time != nil

      assert info.rate_limits == [
               %{
                 "interval" => "MINUTE",
                 "limit" => 2400,
                 "rateLimitType" => "REQUEST_WEIGHT",
                 "intervalNum" => 1
               },
               %{
                 "interval" => "MINUTE",
                 "intervalNum" => 1,
                 "limit" => 1200,
                 "rateLimitType" => "ORDERS"
               }
             ]

      assert info.exchange_filters == []
      assert [symbol | _] = info.symbols

      assert symbol == %{
               "baseAsset" => "BTC",
               "contractSize" => 100,
               "baseAssetPrecision" => 8,
               "filters" => [
                 %{
                   "filterType" => "PRICE_FILTER",
                   "maxPrice" => "100000",
                   "minPrice" => "0.1",
                   "tickSize" => "0.1"
                 },
                 %{
                   "filterType" => "LOT_SIZE",
                   "maxQty" => "100000",
                   "minQty" => "1",
                   "stepSize" => "1"
                 },
                 %{
                   "filterType" => "MARKET_LOT_SIZE",
                   "maxQty" => "124191",
                   "minQty" => "1",
                   "stepSize" => "1"
                 },
                 %{"filterType" => "MAX_NUM_ORDERS", "limit" => 200},
                 %{"filterType" => "MAX_NUM_ALGO_ORDERS", "limit" => 0},
                 %{
                   "filterType" => "PERCENT_PRICE",
                   "multiplierDecimal" => "4",
                   "multiplierDown" => "0.9500",
                   "multiplierUp" => "1.0500"
                 }
               ],
               "contractStatus" => "TRADING",
               "contractType" => "CURRENT_QUARTER",
               "deliveryDate" => 1_601_020_800_000,
               "equalQtyPrecision" => 4,
               "marginAsset" => "BTC",
               "onboardDate" => 1_591_689_600_000,
               "pair" => "BTCUSD",
               "symbol" => "BTCUSD_200925",
               "maintMarginPercent" => "2.5000",
               "orderTypes" => [
                 "LIMIT",
                 "MARKET",
                 "STOP",
                 "STOP_MARKET",
                 "TAKE_PROFIT",
                 "TAKE_PROFIT_MARKET",
                 "TRAILING_STOP_MARKET"
               ],
               "pricePrecision" => 1,
               "quantityPrecision" => 0,
               "quoteAsset" => "USD",
               "quotePrecision" => 8,
               "requiredMarginPercent" => "5.0000",
               "timeInForce" => ["GTC", "IOC", "FOK", "GTX"]
             }
    end
  end

  describe ".create_listen_key" do
    test "returns a listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "coin/create_listen_key_ok" do
        assert Binance.FuturesCoin.create_listen_key(%{}, nil) == {
                 :ok,
                 %{
                   "listenKey" =>
                     "IxySvyspnRKR3Ehx8PSicH6ZirxM5qabauLthZuLIKiGFT4NNnYRX4fRwc2MuGwC"
                 }
               }
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "coin/keep_alive_listen_key_ok" do
        assert Binance.FuturesCoin.keep_alive_listen_key(%{}) == {:ok, %{}}
      end
    end
  end

  describe ".get_depth" do
    test "returns the bids & asks up to the given depth" do
      use_cassette "coin/get_depth_ok" do
        assert Binance.FuturesCoin.get_depth("BTCUSD_PERP", 5) == {
                 :ok,
                 %Binance.OrderBook{
                   asks: [
                     ["12245.1", "46"],
                     ["12245.8", "62"],
                     ["12245.9", "807"],
                     ["12246.0", "25"],
                     ["12247.5", "75"]
                   ],
                   bids: [
                     ["12241.5", "82"],
                     ["12240.5", "11"],
                     ["12239.4", "33"],
                     ["12237.7", "29"],
                     ["12237.6", "27"]
                   ],
                   last_update_id: 1_816_773_996
                 }
               }
      end
    end

    test "returns an error tuple when the symbol doesn't exist" do
      use_cassette "coin/get_depth_error" do
        assert Binance.FuturesCoin.get_depth("IDONTEXIST", 1000) ==
                 {:error, {:binance_error, %{code: -1121, msg: "Invalid symbol."}}}
      end
    end
  end

  describe ".get_account" do
    test "returns current account information" do
      use_cassette "coin/get_account_ok" do
        assert Binance.FuturesCoin.get_account() ==
                 {:ok,
                  %{
                    "assets" => [
                      %{
                        "asset" => "BTC",
                        "availableBalance" => "0.01689600",
                        "crossUnPnl" => "0.00000000",
                        "crossWalletBalance" => "0.01689600",
                        "initialMargin" => "0.00000000",
                        "maintMargin" => "0.00000000",
                        "marginBalance" => "0.01689600",
                        "maxWithdrawAmount" => "0.01689600",
                        "openOrderInitialMargin" => "0.00000000",
                        "positionInitialMargin" => "0.00000000",
                        "unrealizedProfit" => "0.00000000",
                        "walletBalance" => "0.01689600"
                      },
                      %{
                        "asset" => "ADA",
                        "availableBalance" => "0.00000000",
                        "crossUnPnl" => "0.00000000",
                        "crossWalletBalance" => "0.00000000",
                        "initialMargin" => "0.00000000",
                        "maintMargin" => "0.00000000",
                        "marginBalance" => "0.00000000",
                        "maxWithdrawAmount" => "0.00000000",
                        "openOrderInitialMargin" => "0.00000000",
                        "positionInitialMargin" => "0.00000000",
                        "unrealizedProfit" => "0.00000000",
                        "walletBalance" => "0.00000000"
                      },
                      %{
                        "asset" => "LINK",
                        "availableBalance" => "0.00000000",
                        "crossUnPnl" => "0.00000000",
                        "crossWalletBalance" => "0.00000000",
                        "initialMargin" => "0.00000000",
                        "maintMargin" => "0.00000000",
                        "marginBalance" => "0.00000000",
                        "maxWithdrawAmount" => "0.00000000",
                        "openOrderInitialMargin" => "0.00000000",
                        "positionInitialMargin" => "0.00000000",
                        "unrealizedProfit" => "0.00000000",
                        "walletBalance" => "0.00000000"
                      },
                      %{
                        "asset" => "ETH",
                        "availableBalance" => "0.00000000",
                        "crossUnPnl" => "0.00000000",
                        "crossWalletBalance" => "0.00000000",
                        "initialMargin" => "0.00000000",
                        "maintMargin" => "0.00000000",
                        "marginBalance" => "0.00000000",
                        "maxWithdrawAmount" => "0.00000000",
                        "openOrderInitialMargin" => "0.00000000",
                        "positionInitialMargin" => "0.00000000",
                        "unrealizedProfit" => "0.00000000",
                        "walletBalance" => "0.00000000"
                      }
                    ],
                    "canDeposit" => true,
                    "canTrade" => true,
                    "canWithdraw" => true,
                    "feeTier" => 0,
                    "positions" => [
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "250",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "BTCUSD_201225",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "5000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "ETHUSD_200925",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "5000000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "ADAUSD_200925",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "250",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "BTCUSD_PERP",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "250",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "BTCUSD_200925",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "1000000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "LINKUSD_200925",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "5000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "ETHUSD_201225",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "5000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "ETHUSD_PERP",
                        "unrealizedProfit" => "0.00000000"
                      },
                      %{
                        "entryPrice" => "0.0",
                        "initialMargin" => "0",
                        "isolated" => false,
                        "leverage" => "20",
                        "maintMargin" => "0",
                        "maxQty" => "5000000",
                        "openOrderInitialMargin" => "0",
                        "positionInitialMargin" => "0",
                        "positionSide" => "BOTH",
                        "symbol" => "ADAUSD_201225",
                        "unrealizedProfit" => "0.00000000"
                      }
                    ],
                    "updateTime" => 0
                  }}
      end
    end
  end

  describe ".get_position" do
    test "returns current position information" do
      use_cassette "coin/get_position_ok" do
        assert Binance.FuturesCoin.get_position() ==
                 {:ok,
                  [
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "250",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "BTCUSD_201225",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "5000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "ETHUSD_200925",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "5000000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "ADAUSD_200925",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "12277.17934167",
                      "maxQty" => "250",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "BTCUSD_PERP",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "250",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "BTCUSD_200925",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "1000000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "LINKUSD_200925",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "5000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "ETHUSD_201225",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "5000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "ETHUSD_PERP",
                      "unRealizedProfit" => "0.00000000"
                    },
                    %{
                      "entryPrice" => "0.0",
                      "isAutoAddMargin" => "false",
                      "isolatedMargin" => "0.00000000",
                      "leverage" => "20",
                      "liquidationPrice" => "0",
                      "marginType" => "cross",
                      "markPrice" => "0.00000000",
                      "maxQty" => "5000000",
                      "positionAmt" => "0",
                      "positionSide" => "BOTH",
                      "symbol" => "ADAUSD_201225",
                      "unRealizedProfit" => "0.00000000"
                    }
                  ]}
      end
    end
  end

  describe ".create_order limit buy" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "coin/order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, response} =
                 Binance.FuturesCoin.create_order(%{
                   symbol: "BTCUSD_PERP",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 1,
                   price: 11000,
                   time_in_force: "GTC"
                 })

        assert response["clientOrderId"] == "czZw552jagTERPreGivCeK"
        assert response["cumQty"] == "0"
        assert response["executedQty"] == "0"
        assert response["orderId"] == 23_972_434
        assert response["origQty"] == "1"
        assert response["price"] == "11000"
        assert response["reduceOnly"] == false
        assert response["side"] == "BUY"
        assert response["status"] == "NEW"
        assert response["stopPrice"] == "0"
        assert response["symbol"] == "BTCUSD_PERP"
        assert response["timeInForce"] == "GTC"
        assert response["type"] == "LIMIT"
        assert response["time"] == nil
        assert response["updateTime"] == 1_597_747_080_425
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "coin/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason} =
                 Binance.FuturesCoin.create_order(%{
                   symbol: "BTCUSD_PERP",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 50,
                   price: 11000,
                   time_in_force: "GTC"
                 })

        # Binance.Futures.create_order("BTCUSDT", "BUY", "LIMIT", 0.05, 9000)

        assert reason ==
                 {:binance_error,
                  %{
                    code: -2019,
                    msg: "Margin is insufficient."
                  }}
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "coin/order_limit_sell_good_til_cancel_default_duration_success" do
        assert {:ok, response} =
                 Binance.FuturesCoin.create_order(%{
                   symbol: "BTCUSD_PERP",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 1,
                   price: 13000,
                   time_in_force: "GTC"
                 })

        assert response["clientOrderId"] == "9OJHLQS6gEhedqn4idsXkc"
        assert response["cumQty"] == "0"
        assert response["executedQty"] == "0"
        assert response["orderId"] == 23_994_864
        assert response["origQty"] == "1"
        assert response["price"] == "13000"
        assert response["reduceOnly"] == false
        assert response["side"] == "SELL"
        assert response["status"] == "NEW"
        assert response["stopPrice"] == "0"
        assert response["symbol"] == "BTCUSD_PERP"
        assert response["timeInForce"] == "GTC"
        assert response["type"] == "LIMIT"
        assert response["updateTime"] == 1_597_747_827_381
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "coin/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason} =
                 Binance.FuturesCoin.create_order(%{
                   symbol: "BTCUSD_PERP",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 1000,
                   price: 13000,
                   time_in_force: "GTC"
                 })

        assert reason ==
                 {:binance_error,
                  %{
                    code: -2019,
                    msg: "Margin is insufficient."
                  }}
      end
    end
  end

  describe ".get_open_orders" do
    test "when called with symbol returns all open orders for all symbols" do
      use_cassette "coin/get_open_orders_with_symbol_success" do
        assert {:ok,
                [
                  %{
                    "avgPrice" => "0.0",
                    "clientOrderId" => "9OJHLQS6gEhedqn4idsXkc",
                    "closePosition" => false,
                    "cumBase" => "0",
                    "executedQty" => "0",
                    "orderId" => 23_994_864,
                    "origQty" => "1",
                    "origType" => "LIMIT",
                    "pair" => "BTCUSD",
                    "positionSide" => "BOTH",
                    "price" => "13000",
                    "priceProtect" => false,
                    "reduceOnly" => false,
                    "side" => "SELL",
                    "status" => "NEW",
                    "stopPrice" => "0",
                    "symbol" => "BTCUSD_PERP",
                    "time" => 1_597_747_827_381,
                    "timeInForce" => "GTC",
                    "type" => "LIMIT",
                    "updateTime" => 1_597_747_973_144,
                    "workingType" => "CONTRACT_PRICE"
                  },
                  %{
                    "avgPrice" => "0.0",
                    "clientOrderId" => "4rBNPqB30jIC6qBrl1CPaR",
                    "closePosition" => false,
                    "cumBase" => "0",
                    "executedQty" => "0",
                    "orderId" => 23_994_302,
                    "origQty" => "1",
                    "origType" => "LIMIT",
                    "pair" => "BTCUSD",
                    "positionSide" => "BOTH",
                    "price" => "13000",
                    "priceProtect" => false,
                    "reduceOnly" => false,
                    "side" => "SELL",
                    "status" => "NEW",
                    "stopPrice" => "0",
                    "symbol" => "BTCUSD_PERP",
                    "time" => 1_597_747_795_900,
                    "timeInForce" => "GTC",
                    "type" => "LIMIT",
                    "updateTime" => 1_597_747_973_144,
                    "workingType" => "CONTRACT_PRICE"
                  },
                  %{
                    "avgPrice" => "0.0",
                    "clientOrderId" => "czZw552jagTERPreGivCeK",
                    "closePosition" => false,
                    "cumBase" => "0",
                    "executedQty" => "0",
                    "orderId" => 23_972_434,
                    "origQty" => "1",
                    "origType" => "LIMIT",
                    "pair" => "BTCUSD",
                    "positionSide" => "BOTH",
                    "price" => "11000",
                    "priceProtect" => false,
                    "reduceOnly" => false,
                    "side" => "BUY",
                    "status" => "NEW",
                    "stopPrice" => "0",
                    "symbol" => "BTCUSD_PERP",
                    "time" => 1_597_747_080_425,
                    "timeInForce" => "GTC",
                    "type" => "LIMIT",
                    "updateTime" => 1_597_747_973_144,
                    "workingType" => "CONTRACT_PRICE"
                  }
                ]} = Binance.FuturesCoin.get_open_orders()
      end
    end
  end

  describe ".get_order" do
    test "gets an order information by exchange order id" do
      use_cassette "coin/get_order_by_exchange_order_id_ok" do
        assert {:ok,
                %{
                  "avgPrice" => "0.0",
                  "clientOrderId" => "czZw552jagTERPreGivCeK",
                  "closePosition" => false,
                  "cumBase" => "0",
                  "executedQty" => "0",
                  "orderId" => 23_972_434,
                  "origQty" => "1",
                  "origType" => "LIMIT",
                  "pair" => "BTCUSD",
                  "positionSide" => "BOTH",
                  "price" => "11000",
                  "priceProtect" => false,
                  "reduceOnly" => false,
                  "side" => "BUY",
                  "status" => "NEW",
                  "stopPrice" => "0",
                  "symbol" => "BTCUSD_PERP",
                  "time" => 1_597_747_080_425,
                  "timeInForce" => "GTC",
                  "type" => "LIMIT",
                  "updateTime" => 1_597_747_080_425,
                  "workingType" => "CONTRACT_PRICE"
                }} = Binance.FuturesCoin.get_order(%{symbol: "BTCUSD_PERP", order_id: 23_972_434})
      end
    end

    test "gets an order information by client order id" do
      use_cassette "coin/get_order_by_client_order_id_ok" do
        assert {:ok,
                %{
                  "avgPrice" => "0.0",
                  "clientOrderId" => "czZw552jagTERPreGivCeK",
                  "closePosition" => false,
                  "cumBase" => "0",
                  "executedQty" => "0",
                  "orderId" => 23_972_434,
                  "origQty" => "1",
                  "origType" => "LIMIT",
                  "pair" => "BTCUSD",
                  "positionSide" => "BOTH",
                  "price" => "11000",
                  "priceProtect" => false,
                  "reduceOnly" => false,
                  "side" => "BUY",
                  "status" => "NEW",
                  "stopPrice" => "0",
                  "symbol" => "BTCUSD_PERP",
                  "time" => 1_597_747_080_425,
                  "timeInForce" => "GTC",
                  "type" => "LIMIT",
                  "updateTime" => 1_597_747_080_425,
                  "workingType" => "CONTRACT_PRICE"
                }} =
                 Binance.FuturesCoin.get_order(%{
                   symbol: "BTCUSD_PERP",
                   orig_client_order_id: "czZw552jagTERPreGivCeK"
                 })
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "coin/get_order_error" do
        assert Binance.FuturesCoin.get_order(%{symbol: "BTCUSD_PERP", order_id: 123_456_789}) ==
                 {:error, {:binance_error, %{code: -2013, msg: "Order does not exist."}}}
      end
    end
  end

  describe ".cancel_order" do
    test "cancel an order by exchange order id" do
      use_cassette "coin/cancel_order_by_exchange_order_id_ok" do
        assert {:ok,
                %{
                  "avgPrice" => "0.0",
                  "clientOrderId" => "czZw552jagTERPreGivCeK",
                  "closePosition" => false,
                  "cumBase" => "0",
                  "cumQty" => "0",
                  "executedQty" => "0",
                  "orderId" => 23_972_434,
                  "origQty" => "1",
                  "origType" => "LIMIT",
                  "pair" => "BTCUSD",
                  "positionSide" => "BOTH",
                  "price" => "11000",
                  "priceProtect" => false,
                  "reduceOnly" => false,
                  "side" => "BUY",
                  "status" => "CANCELED",
                  "stopPrice" => "0",
                  "symbol" => "BTCUSD_PERP",
                  "timeInForce" => "GTC",
                  "type" => "LIMIT",
                  "updateTime" => 1_597_748_582_738,
                  "workingType" => "CONTRACT_PRICE"
                }} =
                 Binance.FuturesCoin.cancel_order(%{symbol: "BTCUSD_PERP", order_id: 23_972_434})
      end
    end

    test "cancel an order by client order id" do
      use_cassette "coin/cancel_order_by_client_order_id_ok" do
        assert {:ok,
                %{
                  "avgPrice" => "0.0",
                  "clientOrderId" => "9OJHLQS6gEhedqn4idsXkc",
                  "closePosition" => false,
                  "cumBase" => "0",
                  "cumQty" => "0",
                  "executedQty" => "0",
                  "orderId" => 23_994_864,
                  "origQty" => "1",
                  "origType" => "LIMIT",
                  "pair" => "BTCUSD",
                  "positionSide" => "BOTH",
                  "price" => "13000",
                  "priceProtect" => false,
                  "reduceOnly" => false,
                  "side" => "SELL",
                  "status" => "CANCELED",
                  "stopPrice" => "0",
                  "symbol" => "BTCUSD_PERP",
                  "timeInForce" => "GTC",
                  "type" => "LIMIT",
                  "updateTime" => 1_597_748_715_345,
                  "workingType" => "CONTRACT_PRICE"
                }} =
                 Binance.FuturesCoin.cancel_order(%{
                   symbol: "BTCUSD_PERP",
                   orig_client_order_id: "9OJHLQS6gEhedqn4idsXkc"
                 })
      end
    end

    test "return errors when cancel an non-existing order" do
      use_cassette "coin/cancel_non_existing_order" do
        assert {:error, {:binance_error, %{code: -2011, msg: "Unknown order sent."}}} =
                 Binance.FuturesCoin.cancel_order(%{symbol: "BTCUSD_PERP", order_id: 123_456})
      end
    end

    test "cancel batch order by exchange order id" do
      use_cassette "coin/cancel_batch_order_by_exchange_order_id_ok" do
        assert {:ok, [order1]} =
                 Binance.FuturesCoin.cancel_batch_order(%{
                   symbol: "BTCUSD_PERP",
                   order_id_list: [23_994_302]
                 })

        assert order1["orderId"] == 23_994_302
        assert order1["status"] == "CANCELED"
      end
    end

    test "should cancel all open orders by symbol" do
      use_cassette "coin/cancel_all_orders_by_symbol" do
        {:ok, response} = Binance.FuturesCoin.cancel_all_orders(%{symbol: "BTCUSD_PERP"})

        assert response == %{
                 "code" => 200,
                 "msg" => "The operation of cancel all open order is done."
               }
      end
    end

    test "should return error when cancel all open orders without sending symbol param" do
      use_cassette "coin/cancel_all_orders_by_symbol_error" do
        {:error, response} = Binance.FuturesCoin.cancel_all_orders(%{})

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
      use_cassette "coin/get_best_ticker" do
        assert Binance.FuturesCoin.get_best_ticker("BTCUSD_PERP") ==
                 {:ok,
                  [
                    %{
                      "askPrice" => "12281.0",
                      "askQty" => "30",
                      "bidPrice" => "12279.7",
                      "bidQty" => "33",
                      "pair" => "BTCUSD",
                      "symbol" => "BTCUSD_PERP",
                      "time" => 1_597_749_105_782
                    }
                  ]}
      end
    end

    test "mark price" do
      use_cassette "coin/get_index_price" do
        assert Binance.FuturesCoin.get_index_price("BTCUSD_PERP") ==
                 {:ok,
                  [
                    %{
                      "estimatedSettlePrice" => "12271.17876514",
                      "indexPrice" => "12266.83387500",
                      "lastFundingRate" => "0.00068974",
                      "markPrice" => "12280.70000000",
                      "nextFundingTime" => 1_597_766_400_000,
                      "pair" => "BTCUSD",
                      "symbol" => "BTCUSD_PERP",
                      "time" => 1_597_749_167_000
                    }
                  ]}
      end
    end
  end
end
