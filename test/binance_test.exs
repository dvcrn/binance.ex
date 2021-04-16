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
      assert Binance.get_server_time() == {:ok, 1_616_592_268_319}
    end
  end

  test "get_historical_trades success returns the latest trades" do
    use_cassette "get_historical_trades_ok" do
      assert {:ok, response} = Binance.get_historical_trades("XRPUSDT", 1, nil)
      assert [%Binance.HistoricalTrade{} | _tail] = response
    end

    use_cassette "get_historical_trades_from_id_ok" do
      assert {:ok, response} = Binance.get_historical_trades("XRPUSDT", 1, 28457)
      assert [%Binance.HistoricalTrade{} | _tail] = response
    end
  end

  test "get_exchange_info success returns the trading rules and symbol information" do
    use_cassette "get_exchange_info_ok" do
      assert {:ok, %Binance.ExchangeInfo{} = info} = Binance.get_exchange_info()
      assert info.timezone == "UTC"
      assert info.server_time != nil

      assert info.rate_limits == [
               %{"interval" => "MINUTE", "limit" => 1200, "rateLimitType" => "REQUESTS"},
               %{"interval" => "SECOND", "limit" => 10, "rateLimitType" => "ORDERS"},
               %{"interval" => "DAY", "limit" => 100_000, "rateLimitType" => "ORDERS"}
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
                   "filterType" => "LOT_SIZE",
                   "maxQty" => "100000.00000000",
                   "minQty" => "0.00100000",
                   "stepSize" => "0.00100000"
                 },
                 %{"filterType" => "MIN_NOTIONAL", "minNotional" => "0.00100000"}
               ],
               "icebergAllowed" => false,
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

  test "get_all_prices returns a list of prices for every symbol" do
    use_cassette "get_all_prices_ok" do
      assert {:ok, symbol_prices} = Binance.get_all_prices()
      assert [%Binance.SymbolPrice{price: "0.03040500", symbol: "ETHBTC"} | _tail] = symbol_prices
      assert symbol_prices |> Enum.count() == 1363
    end
  end

  describe ".get_ticker" do
    test "returns a ticker struct with details for the given symbol" do
      use_cassette "get_ticker_ok" do
        assert {
                 :ok,
                 %Binance.Ticker{
                   ask_price: "0.00344600",
                   bid_price: "0.00344400",
                   close_time: 1_616_593_123_159,
                   count: 65580
                 }
               } = Binance.get_ticker("LTCBTC")
      end
    end

    test "returns an error tuple when the symbol doesn't exist" do
      use_cassette "get_ticker_error" do
        assert Binance.get_ticker("IDONTEXIST") == {
                 :error,
                 %{"code" => -1121, "msg" => "Invalid symbol."}
               }
      end
    end
  end

  describe ".get_klines" do
    test "returns the klines for a given symbol and interval" do
      use_cassette "get_klines_ok" do
        assert Binance.get_klines("LTCBTC", "1h") ==
                 {
                   :ok,
                   [
                     %Binance.Kline{
                       close: "0.00349500",
                       close_time: 1_616_029_199_999,
                       high: "0.00350000",
                       ignore: "0",
                       low: "0.00346900",
                       number_of_trades: 2338,
                       open: "0.00349600",
                       open_time: 1_616_025_600_000,
                       quote_asset_volume: "36.31825436",
                       taker_buy_base_asset_volume: "4847.44000000",
                       taker_buy_quote_asset_volume: "16.87297134",
                       volume: "10438.37000000"
                     },
                     %Binance.Kline{
                       close: "0.00347900",
                       close_time: 1_616_032_799_999,
                       high: "0.00349700",
                       ignore: "0",
                       low: "0.00347400",
                       number_of_trades: 1372,
                       open: "0.00349600",
                       open_time: 1_616_029_200_000,
                       quote_asset_volume: "19.65151327",
                       taker_buy_base_asset_volume: "2796.91000000",
                       taker_buy_quote_asset_volume: "9.75640680",
                       volume: "5635.90000000"
                     }
                   ]
                 }
      end
    end

    test "returns error with invalid interval" do
      use_cassette "get_klines_interval_err" do
        assert Binance.get_klines("LTCBTC", "1") ==
                 {:error, %{"code" => -1120, "msg" => "Invalid interval."}}
      end
    end
  end

  describe ".get_depth" do
    test "returns the bids & asks up to the given depth" do
      use_cassette "get_depth_ok" do
        assert Binance.get_depth("BTCUSDT", 5) == {
                 :ok,
                 %Binance.OrderBook{
                   asks: [
                     ["56905.88000000", "0.01215200"],
                     ["56906.08000000", "0.52000000"],
                     ["56910.50000000", "0.07710900"],
                     ["56912.73000000", "0.01494300"],
                     ["56914.61000000", "0.67202300"]
                   ],
                   bids: [
                     ["56902.15000000", "0.00371500"],
                     ["56900.01000000", "0.00144100"],
                     ["56888.97000000", "0.26976200"],
                     ["56888.96000000", "0.55709100"],
                     ["56888.38000000", "0.16033500"]
                   ],
                   last_update_id: 9_699_548_377
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

  describe ".order_limit_buy" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.order_limit_buy("LTCBTC", 0.1, 0.01)

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

    test "creates an order with a duration of good til cancel by default(string quantity and price)" do
      use_cassette "order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.order_limit_buy("LTCBTC", "0.1", "0.01")

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
                 Binance.order_limit_buy("LTCBTC", 0.1, 0.01, "FOK")

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
                 Binance.order_limit_buy("LTCBTC", 0.1, 0.01, "IOC")

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
        assert {:error, reason} = Binance.order_limit_buy("LTCBTC", 10_000, 0.001, "FOK")

        assert reason == %Binance.InsufficientBalanceError{
                 reason: %{
                   code: -2010,
                   msg: "Account has insufficient balance for requested action."
                 }
               }
      end
    end

    test "properly formats orders with very low prices" do
      matches_price = fn response, keys, _recorder_options ->
        [expected_price] = Regex.run(~r/price=[^&]+/, response.request.body)
        String.starts_with?(keys[:request_body], expected_price)
      end

      use_cassette "order_limit_buy_very_low_price", custom_matchers: [matches_price] do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.order_limit_buy("DOGEBTC", 100, 0.000001)

        assert response.client_order_id == "cyNmMk8rcgunB0REmUlbyv"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 71_845_546
        assert response.orig_qty == "100.00000000"
        assert response.price == "0.00000100"
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.symbol == "DOGEBTC"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_616_078_021_041
        assert response.type == "LIMIT"
      end
    end
  end

  describe ".order_limit_sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "order_limit_sell_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.OrderResponse{} = response} =
                 Binance.order_limit_sell("BTCUSDT", 0.001, 50_000)

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
                 Binance.order_limit_sell("BTCUSDT", 0.001, 50_000, "FOK")

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
                 Binance.order_limit_sell("BTCUSDT", 0.001, 50_000, "IOC")

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
        assert {:ok, [%Binance.Order{} = result]} = Binance.get_open_orders("WABIBTC")

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

    test "when called with symbol returns all open orders for that symbols(TradePair struct)" do
      use_cassette "get_open_orders_with_trade_pair_struct_string_success" do
        assert {:ok, [%Binance.Order{} = result]} =
                 Binance.get_open_orders(%Binance.TradePair{:from => "WABI", :to => "BTC"})

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
    test "when called with symbol(struct), orderId and timestamp cancels order" do
      use_cassette "cancel_order_by_struct_symbol_orderId_and_timestamp_success" do
        assert {:ok, %Binance.Order{} = order} =
                 Binance.cancel_order(
                   %Binance.TradePair{:from => "XRP", :to => "USDT"},
                   1_564_000_518_279,
                   212_213_771
                 )

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

    test "when called with symbol(string), orderId and timestamp cancels order" do
      use_cassette "cancel_order_by_symbol_string_orderid_and_timestamp_success" do
        assert {:ok, %Binance.Order{} = order} =
                 Binance.cancel_order(
                   "XRPUSDT",
                   1_564_000_518_279,
                   212_213_771
                 )

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
                 Binance.cancel_order(
                   "XRPUSDT",
                   1_564_000_518_279,
                   nil,
                   "ZM1ReQ1ZwiVoaGgcJcumhH"
                 )

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
end
