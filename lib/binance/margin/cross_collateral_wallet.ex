defmodule Binance.Margin.CrossCollateralWallet do
  @moduledoc """
  Struct for representing a result row as returned by /sapi/v2/futures/loan/wallet
  """

  defstruct [
    :total_cross_collateral,
    :total_borrowed,
    :total_interest,
    :interest_free_limit,
    :asset,
    :cross_collaterals
  ]

  use ExConstructor
end
