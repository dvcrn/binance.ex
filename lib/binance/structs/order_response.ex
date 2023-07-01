defmodule Binance.OrderResponse do
  @moduledoc """
  Response tructure for POST /api/v3/order endpoint.
  All prices and quantities are string representation of floats with 8 decimals (eg: "orig_qty": "10.00000000")
  """

  defstruct [
    :client_order_id,
    :executed_qty,
    :order_id,
    :orig_qty,
    :price,
    :side,
    :status,
    :symbol,
    :time_in_force,
    :transact_time,
    :type
  ]

  use ExConstructor

  @typedoc """
  side: "BUY" | "SELL"
  """
  @type side :: String.t()

  @typedoc """
  status: "NEW" | "PARTIALLY_FILLED" | "FILLED" | "CANCELED" | "PENDING_CANCEL" | "REJECTED" | "EXPIRED"
  """
  @type status :: String.t()

  @typedoc """
  type: "LIMIT" | "MARKET" | "STOP" | "STOP_MARKET" | "TAKE_PROFIT" | "TAKE_PROFIT_MARKET" | "LIMIT_MAKER"
  """
  @type type :: String.t()

  @type t :: %__MODULE__{
          client_order_id: String.t(),
          executed_qty: String.t(),
          order_id: non_neg_integer(),
          orig_qty: String.t(),
          price: String.t(),
          side: side(),
          status: status(),
          symbol: String.t(),
          time_in_force: non_neg_integer(),
          transact_time: non_neg_integer(),
          type: type()
        }
end
