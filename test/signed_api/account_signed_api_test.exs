defmodule AccountSignedApiTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  describe "get account" do
    test "get_account (default)" do
      config = %{access_keys: ["BINANCE_API_KEY", "BINANCE_API_SECRET"]}
      {:ok, result, _} = Binance.get_account(config)
      IO.inspect(result)
    end

    test "get_account (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}
      {:ok, result, _} = Binance.get_account(config)
      IO.inspect(result)
    end

    test "get_account (hmac)" do
      config = %{access_keys: ["HMAC_API_KEY", "HMAC_API_SECRET", "HMAC_API_SECRET_TYPE"]}
      {:ok, result, _} = Binance.get_account(config)
      IO.inspect(result)
    end
  end
end
