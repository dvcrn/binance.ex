defmodule Binance.Config do
  @moduledoc """
  Provides configuration keys settings during the runtime.

  Try binance.ex with iex:

  Binance.Config.set(:api_key, "************")
  Binance.Config.set(:secret_key, "***********")

  """
  def set(:api_key, value), do: Application.put_env(:binance, :api_key, value)
  def set(:secret_key, value), do: Application.put_env(:binance, :secret_key, value)
  end

