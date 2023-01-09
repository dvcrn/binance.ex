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

  @doc """
  Sign a given string using given key using secret key
  """
  def sign_content(key, content, key_type) when key_type == "rsa" do
    {:ok, rsa_priv_key} = ExPublicKey.loads(key)
    {:ok, signature} = ExPublicKey.sign(content, rsa_priv_key)
    "#{Base.encode64(signature)}" |> URI.encode_www_form()
  end

  def sign_content(key, content, _key_type) do
    sign_content(key, content)
  end
end
