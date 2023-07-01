defmodule Binance.ResponseMapping do
  @moduledoc false

  def lookup(path_key) do
    mappings = %{
      "get:/api/v3/klines" => Binance.Structs.Kline
    }

    found = Map.get(mappings, path_key, nil)

    IO.puts("lookup for #{path_key} -- #{inspect(found)}")

    found
  end
end
