defmodule WalletTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  describe "transfer" do
    test "success" do
      use_cassette "wallet/success_transfer" do
        assert Binance.Wallet.transfer(%{type: "MAIN_MARGIN", asset: "BTC", amount: 0.0003}) ==
                 {:ok, %{"tranId" => 64_542_913_129}}
      end
    end

    test "fails" do
      use_cassette "wallet/fail_transfer" do
        assert Binance.Wallet.transfer(%{type: "MARGIN_MAIN", asset: "BTC", amount: 0.001}) ==
                 {:error,
                  {:binance_error, %{code: -3020, msg: "Transfer out amount exceeds max amount."}}}
      end
    end
  end

  describe "api trading status" do
    test "success" do
      use_cassette "wallet/success_api_trading_status" do
        config = %{access_keys: ["BINANCE_API_KEY", "BINANCE_API_SECRET"]}
        result = Binance.Wallet.get_api_trading_status(config)

        assert {:ok,
                %{
                  "data" => %{
                    "isLocked" => false,
                    "plannedRecoverTime" => 0,
                    "triggerCondition" => %{"GCR" => 150, "IFER" => 150, "UFR" => 300},
                    "updateTime" => 0
                  }
                }} == result
      end
    end

    test "fail" do
      use_cassette "fail_api_trading_status" do
        config = %{access_keys: ["BINANCE_API_KEY", "BINANCE_API_SECRET"]}
        result = Binance.Wallet.get_api_trading_status(config)

        assert {:error,
                {:binance_error,
                 %{code: -2015, msg: "Invalid API-key, IP, or permissions for action."}}} ==
                 result
      end
    end
  end
end
