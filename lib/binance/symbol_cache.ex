defmodule Binance.SymbolCache do
  @moduledoc """
  Cache for storing symbol names

  Normalization is done by calling the Binance API and retrieving all available symbols. To avoid that this request is done more than once, results are cache inside this module.
  """

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
