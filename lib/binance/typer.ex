defmodule Binance.Typer do
  defmacro __using__(_opts) do
    quote do
      # IO.inspect(unquote(__MODULE__).__struct__())
      # get struct fields
      # types =
      #   __MODULE__.__struct__()
      #   |> Map.from_struct()
      #   |> Map.keys()
      #   |> Enum.reduce([], fn field, acc ->
      #     case acc do
      #       [] ->
      #         quote do: {field, any()}

      #       val ->
      #         quote do:
      #                 {field, any()}
      #                 | unquote(val)
      #     end
      #   end)

      # @type t :: %__MODULE__{
      #         types
      #       }
    end
  end
end
