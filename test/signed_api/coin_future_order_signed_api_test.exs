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
        symbol: "SOLUSD_PERP",
        side: "BUY",
        type: "LIMIT",
        quantity: 1,
        new_client_order_id: "coin_future_1",
        price: 11.0,
        time_in_force: "GTC"
      }

      # {:ok, result, _} = Binance.CoinFutures.create_order(param, config)

    end

    test "get all order (rsa)" do
      # remember to export the private rsa key to environment variable
      # export RSA_API_SECRET=`cat ./private.pem`

      config = %{access_keys: ["RSA_API_KEY", "RSA_API_SECRET", "RSA_API_SECRET_TYPE"]}

      {:ok, result, _} = Binance.CoinFutures.get_open_orders(%{}, config)
      IO.inspect(result)
    end
  end
end
