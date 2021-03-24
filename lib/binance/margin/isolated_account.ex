defmodule Binance.Margin.IsolatedAccount do
  @moduledoc """
  Struct for representing a result row as returned by /sapi/v1/margin/isolated/account
  """

  defstruct [
    :total_asset_of_btc,
    :total_liability_of_btc,
    :total_net_asset_of_btc,
    :assets
  ]

  use ExConstructor
end
