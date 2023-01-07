defmodule OrderSignedApiTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  describe "place order" do

    test "wallet(rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}
      {:ok, result} = Binance.Wallet.get_api_trading_status(config)
      IO.inspect(result)
    end

    test "wallet(hmac)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["BINANCE_API_KEY", "BINANCE_API_SECRET"]}
      {:ok, result} = Binance.Wallet.get_api_trading_status(config)
      IO.inspect(result)
    end

  end
end
