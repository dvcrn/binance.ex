defmodule Binance.Margin.CrossCollateralInfo do
  @moduledoc """
  Struct for representing a result row as returned by GET /sapi/v2/futures/loan/configs
  """

  defstruct [
    :loan_coin,
    :collateral_coin,
    :rate,
    :margin_call_collateral_rate,
    :liquidation_collateral_rate,
    :current_collateral_rate,
    :interest_rate,
    :interest_grace_period
  ]

  use ExConstructor
end
