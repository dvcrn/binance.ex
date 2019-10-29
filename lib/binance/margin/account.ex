defmodule Binance.Margin.Account do
  @moduledoc """
  Struct for representing a result row as returned by /sapi/v1/margin/account
  """

  defstruct [
    :borrow_enabled,
    :margin_level,
    :total_asset_of_btc,
    :total_liability_of_btc,
    :total_net_asset_of_btc,
    :trade_enabled,
    :transfer_enabled
  ]

  use ExConstructor
end
