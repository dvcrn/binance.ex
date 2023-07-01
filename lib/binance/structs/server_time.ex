defmodule Binance.Structs.ServerTime do
  def new(%{"serverTime" => time}) do
    time
  end
end
