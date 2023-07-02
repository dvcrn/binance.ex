defmodule Binance.Errors.InsufficientBalanceError do
  @enforce_keys [:code, :msg]
  defstruct [:code, :msg]
end
