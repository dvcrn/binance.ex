defmodule Binance.ResponseMapping do
  @moduledoc false

  def lookup(path_key) do
    mappings = %{
      "get:/api/v3/klines" => Binance.Structs.Kline,
      "get:/api/v3/account" => Binance.Structs.Account
    }

    Map.get(mappings, path_key, nil)
  end
end
