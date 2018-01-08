defmodule Binance.SymbolCache do
  use Agent

  @id :binance_symbol_cache

  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: @id)
  end

  def get() do
    case Agent.get(@id, fn state -> state end) do
      nil -> {:error, :not_initialized}
      data -> {:ok, data}
    end
  end

  def store(data) when is_list(data) do
    Agent.update(@id, fn _ -> data end)
  end
end
