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
end
