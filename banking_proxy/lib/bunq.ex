defmodule Bunq do
  @moduledoc """
  API for interacting with the Bunq bank.
  """
  @behaviour BankingProxy.BankingBackend

  use Agent
  alias Bunq.API

  # @impl BankingProxy.BankingBackend
  def start_link(opts) do
    Agent.start_link(fn -> %{opts: opts, conn: nil} end,
      name: __MODULE__
    )
  end

  defp connect(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    api_key = Keyword.fetch!(opts, :api_key)

    account_iban = Keyword.fetch!(opts, :iban)

    private_key =
      Keyword.fetch!(opts, :private_key)
      |> load_private_key()

    installation_token = Keyword.fetch!(opts, :installation_token)
    device_id = Keyword.fetch!(opts, :device_id)

    endpoint
    |> API.create_conn(private_key, api_key, installation_token, device_id)
    |> API.start_session()
    |> API.select_account_with_iban(account_iban)
  end

  @impl BankingProxy.BankingBackend
  def list_payments() do
    with_connection(&API.list_payments/1)
  end

  @impl BankingProxy.BankingBackend
  def list_payments(cursor) do
    with_connection(&API.list_payments(&1, cursor))
  end

  @impl BankingProxy.BankingBackend
  def submit_payment(payment) do
    with_connection(&API.submit_payment(&1, payment))
  end

  defp with_connection(callback) do
    Agent.get_and_update(
      __MODULE__,
      fn %{conn: conn, opts: opts} = state ->
        conn = conn || connect(opts)
        result = callback.(conn)
        {result, %{state | conn: conn}}
      end
    )
  end

  @impl BankingProxy.BankingBackend
  def serialize_connection() do
    [:__struct__, :private_key, :server_public_key]
    # |> :maps.without(conn)
    |> Jason.encode!()
  end

  defp load_private_key(private_key_pem) do
    private_key_pem
    |> :public_key.pem_decode()
    |> Enum.map(&:public_key.pem_entry_decode/1)
    |> List.first()
  end
end
