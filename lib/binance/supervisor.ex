defmodule Binance.Supervisor do
  @moduledoc """
  Supervisor for cache and other required persistence layers
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Binance.SymbolCache
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start(_type, _args) do
    start_link()
  end
end
