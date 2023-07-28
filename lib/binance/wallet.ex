defmodule Binance.Wallet do
  @endpoint "https://api.binance.com"

  alias Binance.Rest.HTTPClient

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  @doc """
  internal binance capital transfer.

  ## Example
  ```
  Binance.Wallet.transfer(%{type: "MARGIN_MAIN", asset: "BTC", amount: 0.001})

  {:ok, 1515390701097}
  ```
  """
  @spec transfer(map(), map() | nil) :: {:ok, map()} | {:error, error()}
  def transfer(
        params,
        config \\ nil
      ) do
    arguments = Map.put(params, :timestamp, params[:timestamp] || :os.system_time(:millisecond))

    case HTTPClient.post_binance("#{@endpoint}/sapi/v1/asset/transfer", arguments, config) do
      {:ok, data} ->
        {:ok, data}

      error ->
        error
    end
  end

  def sub_account_transfer(
        params,
        config \\ nil
      ) do
    arguments = Map.put(params, :timestamp, params[:timestamp] || :os.system_time(:millisecond))

    case HTTPClient.post_binance(
           "#{@endpoint}/sapi/v1/sub-account/universalTransfer",
           arguments,
           config
         ) do
      {:ok, data} ->
        {:ok, data}

      error ->
        error
    end
  end

  def get_api_trading_status(config) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/account/apiTradingStatus", %{}, config) do
      {:ok, data} ->
        {:ok, data}

      error ->
        error
    end
  end
end
