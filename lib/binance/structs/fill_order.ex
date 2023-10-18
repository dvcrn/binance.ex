defmodule Binance.Structs.FillOrder do
@moduledoc """
  An order that filled another order structure for POST /api/v3/order endpoint.
  All prices and quantities are string representation of floats with 8 decimals (eg: "qty": "10.00000000")
  """

  defstruct [
    :price,
    :qty,
    :commission,
    :commission_asset,
    :trade_id
  ]

  use ExConstructor

  @type t :: %__MODULE__{
          price: String.t(),
          qty: String.t(),
          commission: String.t(),
          commission_asset: String.t(),
          trade_id: integer()
        }
end
