defmodule OrderSignedApiTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  describe "place order" do
    test "place order (default)" do
      config = %{access_keys: ["BINANCE_API_KEY", "BINANCE_API_SECRET"]}

      param = %{
        symbol: "SOLUSDT",
        side: "BUY",
        type: "LIMIT",
        quantity: 1,
        new_client_order_id: "play_order_default_test",
        price: 13.31,
        time_in_force: "FOK"
      }

      #{:ok, result, _} = Binance.create_order(param, config)
      #IO.inspect(result)
    end

    test "place order (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      param = %{
        symbol: "SOLUSDT",
        side: "BUY",
        type: "LIMIT",
        quantity: 1,
        new_client_order_id: "play_order_default_test",
        price: 13.31,
        time_in_force: "FOK"
      }

      {:ok, result, _} = Binance.create_order(param, config)
      IO.inspect(result)
    end

  end
end
