defmodule BinanceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    System.put_env("BINANCE_API_KEY", "fake_api_key")
    System.put_env("BINANCE_API_SECRET", "fake_secret_key")
    HTTPoison.start()
  end

  test "ping returns an empty map" do
    use_cassette "ping_ok" do
      assert Binance.ping() == {:ok, %{}}
    end
  end

  test "get_server_time success return an ok, time tuple" do
    use_cassette "get_server_time_ok" do
      assert Binance.get_server_time() == {:ok, 1_573_205_271_410}
    end
  end

  test "get_exchange_info success returns the trading rules and symbol information" do
    use_cassette "get_exchange_info_ok" do
      assert {:ok, %Binance.ExchangeInfo{} = info} = Binance.get_exchange_info()
      assert info.timezone == "UTC"
      assert info.server_time != nil

      assert info.rate_limits == [
               %{
                 "interval" => "MINUTE",
                 "intervalNum" => 1,
                 "limit" => 1200,
                 "rateLimitType" => "REQUEST_WEIGHT"
               },
               %{
                 "interval" => "SECOND",
                 "intervalNum" => 1,
                 "limit" => 10,
                 "rateLimitType" => "ORDERS"
               },
               %{
                 "interval" => "DAY",
                 "intervalNum" => 1,
                 "limit" => 200_000,
                 "rateLimitType" => "ORDERS"
               }
             ]

      assert info.exchange_filters == []
      assert [symbol | _] = info.symbols

      assert symbol == %{
               "baseAsset" => "ETH",
               "baseAssetPrecision" => 8,
               "filters" => [
                 %{
                   "filterType" => "PRICE_FILTER",
                   "maxPrice" => "100000.00000000",
                   "minPrice" => "0.00000100",
                   "tickSize" => "0.00000100"
                 },
                 %{
                   "avgPriceMins" => 5,
                   "filterType" => "PERCENT_PRICE",
                   "multiplierDown" => "0.2",
                   "multiplierUp" => "5"
                 },
                 %{
                   "filterType" => "LOT_SIZE",
                   "maxQty" => "100000.00000000",
                   "minQty" => "0.00100000",
                   "stepSize" => "0.00100000"
                 },
                 %{
                   "applyToMarket" => true,
                   "avgPriceMins" => 5,
                   "filterType" => "MIN_NOTIONAL",
                   "minNotional" => "0.00010000"
                 },
                 %{"filterType" => "ICEBERG_PARTS", "limit" => 10},
                 %{
                   "filterType" => "MARKET_LOT_SIZE",
                   "maxQty" => "63100.00000000",
                   "minQty" => "0.00000000",
                   "stepSize" => "0.00000000"
                 },
                 %{"filterType" => "MAX_NUM_ALGO_ORDERS", "maxNumAlgoOrders" => 5}
               ],
               "icebergAllowed" => true,
               "isMarginTradingAllowed" => true,
               "isSpotTradingAllowed" => true,
               "ocoAllowed" => true,
               "orderTypes" => [
                 "LIMIT",
                 "LIMIT_MAKER",
                 "MARKET",
                 "STOP_LOSS_LIMIT",
                 "TAKE_PROFIT_LIMIT"
               ],
               "quoteAsset" => "BTC",
               "quotePrecision" => 8,
               "status" => "TRADING",
               "symbol" => "ETHBTC"
             }
    end
  end

  describe ".get_ticker" do
    test "returns a ticker struct with details for the given symbol" do
      use_cassette "get_ticker_ok" do
        assert {:ok,
                %Binance.Ticker{
                  ask_price: "0.00669900",
                  bid_price: "0.00669600",
                  close_time: 1_573_205_275_494,
                  count: 23994,
                  first_id: 35_642_100,
                  high_price: "0.00676100",
                  last_id: 35_666_093,
                  last_price: "0.00669900",
                  low_price: "0.00655800",
                  open_price: "0.00671200",
                  open_time: 1_573_118_875_494,
                  prev_close_price: "0.00671300",
                  price_change: "-0.00001300",
                  price_change_percent: "-0.194",
                  volume: "123522.34000000",
                  weighted_avg_price: "0.00667994"
                }} = Binance.get_ticker("LTCBTC")
      end
    end

    test "returns an error tuple when the symbol doesn't exist" do
      use_cassette "get_ticker_error" do
        assert Binance.get_ticker("IDONTEXIST") ==
                 {:error, {:binance_error, %{code: -1121, msg: "Invalid symbol."}}}
      end
    end
  end

  describe ".create_listen_key" do
    test "returns a listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "create_listen_key_ok" do
        assert Binance.create_listen_key() == {
                 :ok,
                 %{
                   "listenKey" => "AoaTlfkZv6KtpFLIiNn08x8hX51Hcy2MURjwnraU1rvmTlm4pdtkNdJDIpO2"
                 }
               }
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "keep_alive_listen_key_ok" do
        assert Binance.keep_alive_listen_key(
                 "AoaTlfkZv6KtpFLIiNn08x8hX51Hcy2MURjwnraU1rvmTlm4pdtkNdJDIpO2"
               ) == {:ok, %{}}
      end
    end
  end

  describe ".get_depth" do
    test "returns the bids & asks up to the given depth" do
      use_cassette "get_depth_ok" do
        assert Binance.get_depth("BTCUSDT", 5) ==
                 {:ok,
                  %Binance.OrderBook{
                    asks: [
                      ["9019.25000000", "0.44862000"],
                      ["9019.29000000", "0.12076700"],
                      ["9019.31000000", "0.55440600"],
                      ["9020.22000000", "0.02162700"],
                      ["9020.23000000", "2.00000000"]
                    ],
                    bids: [
                      ["9017.97000000", "0.09418300"],
                      ["9017.91000000", "0.22854400"],
                      ["9016.20000000", "0.10200000"],
                      ["9015.47000000", "0.02218400"],
                      ["9015.21000000", "0.15102300"]
                    ],
                    last_update_id: 1_307_751_521
                  }}
      end
    end

    test "returns an error tuple when the symbol doesn't exist" do
      use_cassette "get_depth_error" do
        assert Binance.get_depth("IDONTEXIST", 1000) ==
                 {:error, {:binance_error, %{code: -1121, msg: "Invalid symbol."}}}
      end
    end
  end

  describe ".create_order limit buy" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(%{
                   symbol: "LTCBTC",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.1,
                   price: 0.01,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "9kITBshSwrClye1HJcLM3j"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 47_511_548
        assert response.orig_qty == "0.10000000"
        assert response.price == "0.01000000"
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.symbol == "LTCBTC"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_527_278_150_709
        assert response.type == "LIMIT"
      end
    end

    test "can create an order with a fill or kill duration" do
      use_cassette "order_limit_buy_fill_or_kill_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(%{
                   symbol: "LTCBTC",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.1,
                   price: 0.01,
                   time_in_force: "FOK"
                 })

        assert response.client_order_id == "dY67P33S4IxPnJGx5EtuSf"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 47_527_179
        assert response.orig_qty == "0.10000000"
        assert response.price == "0.01000000"
        assert response.side == "BUY"
        assert response.status == "EXPIRED"
        assert response.symbol == "LTCBTC"
        assert response.time_in_force == "FOK"
        assert response.transact_time == 1_527_290_557_607
        assert response.type == "LIMIT"
      end
    end

    test "can create an order with am immediate or cancel duration" do
      use_cassette "order_limit_buy_immediate_or_cancel_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(
                   %{
                     symbol: "LTCBTC",
                     side: "BUY",
                     type: "LIMIT",
                     quantity: 0.1,
                     price: 0.01,
                     time_in_force: "IOC"
                   },
                   nil
                 )

        assert response.client_order_id == "zyMyhtRENlvFHrl4CitDe0"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 47_528_830
        assert response.orig_qty == "0.10000000"
        assert response.price == "0.01000000"
        assert response.side == "BUY"
        assert response.status == "EXPIRED"
        assert response.symbol == "LTCBTC"
        assert response.time_in_force == "IOC"
        assert response.transact_time == 1_527_291_300_912
        assert response.type == "LIMIT"
      end
    end

    test "returns an insufficient balance error tuple" do
      use_cassette "order_limit_buy_error_insufficient_balance" do
        assert {:error, reason} =
                 Binance.create_order(%{
                   symbol: "LTCBTC",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 10_000,
                   price: 0.001,
                   time_in_force: "FOK"
                 })

        assert reason ==
                 {:binance_error,
                  %{
                    code: -2010,
                    msg: "Account has insufficient balance for requested action."
                  }}
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "order_limit_sell_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 50_000,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "9UFMPloZsQ3eshCx66PVqD"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 108_212_133
        assert response.orig_qty == "0.00100000"
        assert response.price == "50000.00000000"
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_527_279_796_770
        assert response.type == "LIMIT"
      end
    end

    test "can create an order with a fill or kill duration" do
      use_cassette "order_limit_sell_fill_or_kill_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 50_000,
                   time_in_force: "FOK"
                 })

        assert response.client_order_id == "lKYECwEPSTPzurwx6emuN2"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 108_277_184
        assert response.orig_qty == "0.00100000"
        assert response.price == "50000.00000000"
        assert response.side == "SELL"
        assert response.status == "EXPIRED"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "FOK"
        assert response.transact_time == 1_527_290_985_305
        assert response.type == "LIMIT"
      end
    end

    test "can create an order with am immediate or cancel duration" do
      use_cassette "order_limit_sell_immediate_or_cancel_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 50_000,
                   time_in_force: "IOC"
                 })

        assert response.client_order_id == "roSkLhwX9KCgYqr4yFPx1V"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 108_279_070
        assert response.orig_qty == "0.00100000"
        assert response.price == "50000.00000000"
        assert response.side == "SELL"
        assert response.status == "EXPIRED"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "IOC"
        assert response.transact_time == 1_527_291_411_088
        assert response.type == "LIMIT"
      end
    end
  end

  describe ".get_open_orders" do
    test "when called without symbol returns all open orders for all symbols" do
      use_cassette "get_open_orders_without_symbol_success" do
        assert {:ok, [%Binance.Order{} = order_1, %Binance.Order{} = order_2]} =
                 Binance.get_open_orders()

        # open order 1

        assert order_1.client_order_id == "web_6b6a916821d342fd861faa5139b229d2"
        assert order_1.cummulative_quote_qty == "0.00000000"
        assert order_1.executed_qty == "0.00000000"
        assert order_1.iceberg_qty == "0.00000000"
        assert order_1.is_working == true
        assert order_1.order_id == 148_740_811
        assert order_1.orig_qty == "177.00000000"
        assert order_1.price == "0.00050000"
        assert order_1.side == "SELL"
        assert order_1.status == "NEW"
        assert order_1.stop_price == "0.00000000"
        assert order_1.symbol == "XRPBTC"
        assert order_1.time == 1_556_710_572_734
        assert order_1.time_in_force == "GTC"
        assert order_1.type == "LIMIT"
        assert order_1.update_time == 1_556_710_572_734

        # open order 2

        assert order_2.client_order_id == "web_db04d8a507f14135a9a9d4467bc541a1"
        assert order_2.cummulative_quote_qty == "0.00000000"
        assert order_2.executed_qty == "0.00000000"
        assert order_2.iceberg_qty == "0.00000000"
        assert order_2.is_working == true
        assert order_2.order_id == 42_240_233
        assert order_2.orig_qty == "215.00000000"
        assert order_2.price == "0.00064200"
        assert order_2.side == "SELL"
        assert order_2.status == "NEW"
        assert order_2.stop_price == "0.00000000"
        assert order_2.symbol == "WABIBTC"
        assert order_2.time == 1_556_710_717_616
        assert order_2.time_in_force == "GTC"
        assert order_2.type == "LIMIT"
        assert order_2.update_time == 1_556_710_717_616
      end
    end

    test "when called with symbol returns all open orders for that symbols(string)" do
      use_cassette "get_open_orders_with_symbol_string_success" do
        assert {:ok, [%Binance.Order{} = result]} = Binance.get_open_orders(%{symbol: "WABIBTC"})

        assert result.client_order_id == "web_db04d8a507f14135a9a9d4467bc541a1"
        assert result.cummulative_quote_qty == "0.00000000"
        assert result.executed_qty == "0.00000000"
        assert result.iceberg_qty == "0.00000000"
        assert result.is_working == true
        assert result.order_id == 42_240_233
        assert result.orig_qty == "215.00000000"
        assert result.price == "0.00064200"
        assert result.side == "SELL"
        assert result.status == "NEW"
        assert result.stop_price == "0.00000000"
        assert result.symbol == "WABIBTC"
        assert result.time == 1_556_710_717_616
        assert result.time_in_force == "GTC"
        assert result.type == "LIMIT"
        assert result.update_time == 1_556_710_717_616
      end
    end
  end

  describe ".cancel_order" do
    test "when called with symbol(string), orderId and timestamp cancels order" do
      use_cassette "cancel_order_by_symbol_string_orderid_and_timestamp_success" do
        assert {:ok, %Binance.Order{} = order} =
                 Binance.cancel_order(%{
                   symbol: "XRPUSDT",
                   order_id: 212_213_771
                 })

        assert order.client_order_id == "iBz2JsX9hCsR6LRv6lqKld"
        assert order.cummulative_quote_qty == "0.00000000"
        assert order.executed_qty == "0.00000000"
        assert order.iceberg_qty == nil
        assert order.is_working == nil
        assert order.order_id == 212_213_771
        assert order.orig_qty == "100.00000000"
        assert order.price == "0.30000000"
        assert order.side == "BUY"
        assert order.status == "CANCELED"
        assert order.stop_price == nil
        assert order.symbol == "XRPUSDT"
        assert order.time == nil
        assert order.time_in_force == "GTC"
        assert order.type == "LIMIT"
        assert order.update_time == nil
      end
    end

    test "when called with symbol(string), clientOrderId and timestamp cancels order" do
      use_cassette "cancel_order_by_symbol_string_clientOrderId_and_timestamp_success" do
        assert {:ok, %Binance.Order{} = order} =
                 Binance.cancel_order(%{
                   symbol: "XRPUSDT",
                   orig_client_order_id: "ZM1ReQ1ZwiVoaGgcJcumhH"
                 })

        assert order.client_order_id == "gKMdjRw8fDkpObd0fXjCRZ"
        assert order.cummulative_quote_qty == "0.00000000"
        assert order.executed_qty == "0.00000000"
        assert order.iceberg_qty == nil
        assert order.is_working == nil
        assert order.order_id == 212_217_782
        assert order.orig_qty == "100.00000000"
        assert order.price == "0.30000000"
        assert order.side == "BUY"
        assert order.status == "CANCELED"
        assert order.stop_price == nil
        assert order.symbol == "XRPUSDT"
        assert order.time == nil
        assert order.time_in_force == "GTC"
        assert order.type == "LIMIT"
        assert order.update_time == nil
      end
    end
  end

  describe "get" do
    test "best ticker" do
      use_cassette "get_best_ticker" do
        assert Binance.Margin.get_best_ticker("BTCUSDT") ==
                 {:ok,
                  %{
                    "symbol" => "BTCUSDT",
                    "askPrice" => "9017.33000000",
                    "askQty" => "0.14430800",
                    "bidPrice" => "9015.11000000",
                    "bidQty" => "0.06305200"
                  }}
      end
    end
  end
end
