defmodule Binance.Config do
  require Logger

  @type t :: %Binance.Config{
          api_key: String.t(),
          api_secret: String.t(),
          api_secret_type: String.t()
        }

  @enforce_keys [:api_key, :api_secret, :api_secret_type]
  defstruct [:api_key, :api_secret, :api_secret_type]

  @doc """
  Get default API configs

  ## Examples
      iex> Binance.Config.get()
  """
  def get(nil) do
    %__MODULE__{
      api_key: System.get_env("BINANCE_API_KEY"),
      api_secret: System.get_env("BINANCE_API_SECRET"),
      api_secret_type: System.get_env("BINANCE_API_SECRET_TYPE")
    }
  end

  @doc """
  Get dynamic API configs via ENVs

  ## Examples
      iex> Binance.Config.get(%{access_keys: ["B1_API_KEY", "B1_API_SECRET"]})
  """
  def get(%{
        access_keys: [api_key_access, api_secret_access]
      }) do
    %__MODULE__{
      api_key: System.get_env(api_key_access),
      api_secret: System.get_env(api_secret_access),
      api_secret_type: nil
    }
  end

  @doc """
  Get dynamic API configs via ENVs

  ## Examples
      iex> Binance.Config.get(%{access_keys: ["B1_API_KEY", "B1_API_SECRET", "B1_API_SECRET_TYPE"]})
  """
  def get(%{
        access_keys: [api_key_access, api_secret_access, api_secret_type_access]
      }) do
    %__MODULE__{
      api_key: System.get_env(api_key_access),
      api_secret: System.get_env(api_secret_access),
      api_secret_type: System.get_env(api_secret_type_access)
    }
  end

  def get(_) do
    Logger.error("Incorrect config setup.")
  end
end
