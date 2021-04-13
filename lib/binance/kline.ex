defmodule Binance.Kline do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/kline

  ```
  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :close_time,
    :quote_asset_volume,
    :number_of_trades,
    :taker_buy_base_asset_volume,
    :taker_buy_quote_asset_volume,
    :ignore
  ]
  ```
  """

  defstruct [
    :open_time,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :close_time,
    :quote_asset_volume,
    :number_of_trades,
    :taker_buy_base_asset_volume,
    :taker_buy_quote_asset_volume,
    :ignore
  ]

  def new(list) do
    %Binance.Kline{
      open_time: Enum.at(list, 0),
      open: Enum.at(list, 1),
      high: Enum.at(list, 2),
      low: Enum.at(list, 3),
      close: Enum.at(list, 4),
      volume: Enum.at(list, 5),
      close_time: Enum.at(list, 6),
      quote_asset_volume: Enum.at(list, 7),
      number_of_trades: Enum.at(list, 8),
      taker_buy_base_asset_volume: Enum.at(list, 9),
      taker_buy_quote_asset_volume: Enum.at(list, 10),
      ignore: Enum.at(list, 11)
    }
  end
end
