defmodule Binance.Futures.Account do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :fee_tier,
    :total_initial_margin,
    :total_maint_margin,
    :total_margin_balance,
    :total_unrealized_profit,
    :total_wallet_balance,
    :can_trade,
    :can_withdraw,
    :can_deposit,
    :assets,
    :update_time,
  ]
  ```
  """

  defstruct [
    :fee_tier,
    :total_initial_margin,
    :total_maint_margin,
    :total_margin_balance,
    :total_unrealized_profit,
    :total_wallet_balance,
    :can_trade,
    :can_withdraw,
    :can_deposit,
    :assets,
    :update_time
  ]

  use ExConstructor
end
