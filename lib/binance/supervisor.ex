defmodule Binance.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Binance.SymbolCache
    ]

    # children = Enum.map(config, fn(c) ->
    #   {c.strategy, [exchange: c.exchange,
    #                 trade_pair: c.trade_pair,
    #                 interval: c.interval,
    #                 config: c.config]}
    # end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start(_type, _args) do
    start_link()
  end
end
