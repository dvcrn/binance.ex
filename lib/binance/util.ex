defmodule Binance.Util do
  @moduledoc false

  @doc """
  Sign a given string using given key
  """
  def sign_content(key, content) do
    # TODO: remove when we require OTP 24
    if Code.ensure_loaded?(:crypto) and function_exported?(:crypto, :mac, 4) do
      :hmac
      |> :crypto.mac(:sha256, key, content)
      |> Base.encode16()
    else
      :sha256
      |> :crypto.hmac(key, content)
      |> Base.encode16()
    end
  end
end
