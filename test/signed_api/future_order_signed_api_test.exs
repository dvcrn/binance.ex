defmodule FutureOrderSignedApiTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  describe "place order" do
    test "place order (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      param = %{
        symbol: "SOLUSDT",
        side: "SELL",
        type: "LIMIT",
        quantity: 1,
        new_client_order_id: "play_order_default_test_1",
        price: 14.0,
        time_in_force: "GTC"
      }

    end

    test "get all order (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      {:ok, result, _} = Binance.Futures.get_open_orders(%{}, config)
      IO.inspect(result)
    end

    test "get order (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      param = %{
        symbol: "SOLUSDT",
        order_id: 20966244754
      }
      #{:ok, result, _} = Binance.Futures.get_order(param, config)
      #IO.inspect(result)
    end

    test "cancel_order(rsa)" do
      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      param = %{
        symbol: "SOLUSDT",
        order_id: 20966227082
      }

      {:ok, result, _} = Binance.Futures.cancel_order(param, config)
      IO.inspect(result)
    end
  end
end
