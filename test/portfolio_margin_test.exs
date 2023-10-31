defmodule PortfolioMarginTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    System.put_env("BINANCE_API_KEY", "fake_api_key")
    System.put_env("BINANCE_API_SECRET", "fake_secret_key")
    HTTPoison.start()
  end

  test "ping returns an empty map" do
    use_cassette "portfolio_margin/ping_ok" do
      assert {:ok, %{}, _rate_limit} = Binance.PortfolioMargin.ping()
    end
  end

  describe ".create_order limit buy" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "portfolio_margin/order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.create_order("um", %{
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
        assert response.avg_price == "8000"
        assert response.price == "8000"
        assert response.reduce_only == false
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.position_side == "BOTH"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_586_855_766_315
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "portfolio_margin/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason, _rate_limit} =
                 Binance.PortfolioMargin.create_order("um", %{
                   symbol: "BTCUSDT",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.05,
                   price: 9000,
                   time_in_force: "GTC"
                 })

        assert reason ==
                 {:binance_error,
                  %{
                    code: -2018,
                    msg: "Balance is insufficient"
                  }}
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "portfolio_margin/order_limit_sell_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.create_order("um", %{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 11_000,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "VV0vLLVnABzLXwYxvDkYqF"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 10_800_687
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.avg_price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.position_side == "BOTH"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_976_216_827
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "portfolio_margin/order_limit_buy_error_insufficient_balance" do
        assert {:error, reason, _rate_limit} =
                 Binance.PortfolioMargin.create_order("um", %{
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
                    code: -2018,
                    msg: "Balance is insufficient"
                  }}
      end
    end
  end

  describe ".get_open_orders" do
    test "when called without symbol returns all open orders for all symbols" do
      use_cassette "portfolio_margin/get_open_orders_without_symbol_success" do
        assert {:ok,
                [
                  %Binance.PortfolioMargin.UMOrder{} = order_1,
                  %Binance.PortfolioMargin.UMOrder{} = order_2
                ], _rate_limit} = Binance.PortfolioMargin.get_open_orders("um")

        assert order_1.client_order_id == "web_argH9snTII2DpZQ1lkzD"
        assert order_1.cum_qty == "0"
        assert order_1.cum_quote == "0"
        assert order_1.executed_qty == "0"
        assert order_1.order_id == 2_634_617_095
        assert order_1.orig_qty == "0.001"
        assert order_1.price == "9000"
        assert order_1.reduce_only == false
        assert order_1.side == "SELL"
        assert order_1.status == "NEW"
        assert order_1.position_side == "BOTH"
        assert order_1.symbol == "BTCUSDT"
        assert order_1.time_in_force == "GTC"
        assert order_1.type == "LIMIT"
        assert order_1.update_time == 1_586_855_589_773

        assert order_2.client_order_id == "web_zyRe8mQWmV2GOoLxdSYr"
        assert order_2.cum_qty == "0"
        assert order_2.cum_quote == "0"
        assert order_2.executed_qty == "0"
        assert order_2.order_id == 2_634_612_040
        assert order_2.orig_qty == "0.001"
        assert order_2.price == "8786.98"
        assert order_2.reduce_only == false
        assert order_2.side == "SELL"
        assert order_2.status == "NEW"
        assert order_2.position_side == "BOTH"
        assert order_2.symbol == "BTCUSDT"
        assert order_2.time_in_force == "GTC"
        assert order_2.type == "LIMIT"
        assert order_2.update_time == 1_586_855_589_773
      end
    end

    test "when called with symbol returns all open orders for that symbols(string)" do
      use_cassette "portfolio_margin/get_open_orders_with_symbol_string_success" do
        assert {:ok, [%Binance.PortfolioMargin.UMOrder{} = order_1], _rate_limit} =
                 Binance.PortfolioMargin.get_open_orders("um", %{symbol: "BTCUSDT"})

        assert order_1.client_order_id == "kFVoo0nClhOku6KbcB8B1X"
        assert order_1.cum_qty == "0"
        assert order_1.cum_quote == "0"
        assert order_1.executed_qty == "0"
        assert order_1.order_id == 11_333_637
        assert order_1.orig_qty == "0.001"
        assert order_1.price == "11000"
        assert order_1.reduce_only == false
        assert order_1.side == "SELL"
        assert order_1.status == "NEW"
        assert order_1.position_side == "BOTH"
        assert order_1.symbol == "BTCUSDT"
        assert order_1.time_in_force == "GTC"
        assert order_1.type == "LIMIT"
        assert order_1.update_time == 1_568_995_541_781
      end
    end
  end

  describe ".get_order" do
    test "gets an order information by exchange order id" do
      use_cassette "portfolio_margin/get_order_by_exchange_order_id_ok" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.get_order("um", %{symbol: "BTCUSDT", order_id: 10_926_974})

        assert response.client_order_id == "F1YDd19xJvGWNiBbt7JCrr"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 10_926_974
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.symbol == "BTCUSDT"
        assert response.position_side == "BOTH"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_988_806_336
      end
    end

    test "gets an order information by client order id" do
      use_cassette "portfolio_margin/get_order_by_client_order_id_ok" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.get_order("um", %{
                   symbol: "BTCUSDT",
                   orig_client_order_id: "Slo0A5UDDOWK7cdUNVUsfO"
                 })

        assert response.client_order_id == "Slo0A5UDDOWK7cdUNVUsfO"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 11_277_192
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "CANCELED"
        assert response.position_side == "BOTH"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_996_656_841
      end
    end

    test "returns an insufficient margin error tuple" do
      use_cassette "portfolio_margin/get_order_error" do
        assert {:error, {:binance_error, %{code: -2013, msg: "Order does not exist."}},
                _rate_limit} =
                 Binance.PortfolioMargin.get_order("um", %{symbol: "BTCUSDT", order_id: 123_456_789})
      end
    end
  end

  describe ".cancel_order" do
    test "cancel an order by exchange order id" do
      use_cassette "portfolio_margin/cancel_order_by_exchange_order_id_ok" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.cancel_order("um", %{symbol: "BTCUSDT", order_id: 11_257_530})

        assert response.client_order_id == "wgQyWAlBFCCWinOy7yPFDu"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 11_222_530
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "CANCELED"
        assert response.position_side == "BOTH"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_999_338_577
      end
    end

    test "cancel an order by client order id" do
      use_cassette "portfolio_margin/cancel_order_by_client_order_id_ok" do
        assert {:ok, %Binance.PortfolioMargin.UMOrder{} = response, _rate_limit} =
                 Binance.PortfolioMargin.cancel_order("um", %{
                   symbol: "BTCUSDT",
                   orig_client_order_id: "Slo0A5UDDOWK7cdUNVUsfO"
                 })

        assert response.client_order_id == "Slo0A5UDDOWK7cdUNVUsfO"
        assert response.cum_qty == "0"
        assert response.cum_quote == "0"
        assert response.executed_qty == "0"
        assert response.order_id == 11_277_192
        assert response.orig_qty == "0.001"
        assert response.price == "11000"
        assert response.reduce_only == false
        assert response.side == "SELL"
        assert response.status == "CANCELED"
        assert response.position_side == "BOTH"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.type == "LIMIT"
        assert response.update_time == 1_568_996_656_841
      end
    end

    test "return errors when cancel an non-existing order" do
      use_cassette "portfolio_margin/cancel_non_existing_order" do
        assert {:error,
          {:binance_error, %{code: -2011, msg: "CANCEL_REJECTED"}},
                _rate_limit} =
                 Binance.PortfolioMargin.cancel_order("um", %{symbol: "BTCUSDT", order_id: 123_456})
      end
    end
  end
end
