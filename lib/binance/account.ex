defmodule Binance.Account do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :maker_commission,
    :taker_commission,
    :buyer_commission,
    :seller_commission,
    :can_trade,
    :can_withdrawl,
    :can_deposit,
    :update_time,
    :balances
  ]
  ```
  """

  defstruct [
    :maker_commission,
    :taker_commission,
    :buyer_commission,
    :seller_commission,
    :can_trade,
    :can_withdrawl,
    :can_deposit,
    :update_time,
    :balances
  ]

  use ExConstructor
end
