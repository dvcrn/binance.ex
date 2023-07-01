defmodule Binance.SystemStatus do
  @moduledoc """
  Struct for representing the result returned by /wapi/v3/systemStatus.html

  ```
  defstruct [:status, :msg]
  ```
  """

  defstruct [:status, :msg]
  use ExConstructor
end
