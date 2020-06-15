defmodule MarginTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    System.put_env("BINANCE_API_KEY", "fake_api_key")
    System.put_env("BINANCE_API_SECRET", "fake_secret_key")
    HTTPoison.start()
  end

  describe ".create_listen_key" do
    test "returns a listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "margin/create_listen_key_ok" do
        assert Binance.Margin.create_listen_key() == {
                 :ok,
                 %{
                   "listenKey" => "cqcFKuqCCRv1QNnhiA4gsdMLSRgTz4qyd0l5JWryjaAxjQlr8JAcyksNt1Ct"
                 }
               }
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "margin/keep_alive_listen_key_ok" do
        assert Binance.Margin.keep_alive_listen_key(
                 "cqcFKuqCCRv1QNnhiA4gsdMLSRgTz4qyd0l5JWryjaAxjQlr8JAcyksNt1Ct"
               ) == {:ok, %{}}
      end
    end
  end

  describe ".get_account" do
    test "returns current account information" do
      use_cassette "margin/get_account_ok" do
        assert Binance.Margin.get_account() == {
                 :ok,
                 %Binance.Margin.Account{
                   borrow_enabled: true,
                   margin_level: "999.00000000",
                   total_asset_of_btc: "0.08256500",
                   total_liability_of_btc: "0.00000000",
                   total_net_asset_of_btc: "0.08256500",
                   trade_enabled: true,
                   transfer_enabled: true
                 }
               }
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates an order with a duration of good til cancel by default" do
      use_cassette "margin/order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.Margin.Order{} = response} =
                 Binance.Margin.create_order(%{
                   symbol: "BTCUSDT",
                   side: "SELL",
                   type: "LIMIT",
                   quantity: 0.004,
                   price: 10_000,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "r0YoPSDp4T5yYnn6fLxeYX"
        assert response.cummulative_quote_qty == "0.00000000"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 746_180_871
        assert response.orig_qty == "0.00400000"
        assert response.price == "10000.00000000"
        assert response.side == "SELL"
        assert response.status == "NEW"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_572_355_225_711
        assert response.type == "LIMIT"
      end
    end
  end

  describe "get" do
    test "best ticker" do
      use_cassette "margin/get_best_ticker" do
        assert Binance.Margin.get_best_ticker("BTCUSDT")
          == {:ok,
                %{
                  "askPrice" => "9046.59000000",
                  "askQty" => "0.49950000",
                  "bidPrice" => "9046.03000000",
                  "bidQty" => "0.62312800",
                  "symbol" => "BTCUSDT"
                }
              }
      end
    end
  end
end
