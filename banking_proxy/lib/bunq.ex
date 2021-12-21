defmodule Bunq do
  @moduledoc """
  API for interacting with the Bunq bank.
  """
  @behaviour BankingProxy.BankingBackend

  use Agent
  alias Bunq.{API, Cursor}

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
      Keyword.fetch!(opts, :keyfile)
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
    |> format_list_payment_response()
  end

  @impl BankingProxy.BankingBackend
  def list_payments(cursor_string) do
    cursor_data = Jason.decode!(cursor_string, keys: :atoms!)
    cursor = struct!(Cursor, cursor_data)

    with_connection(&API.list_payments(&1, cursor))
    |> format_list_payment_response()
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
    |> File.read!()
    |> :public_key.pem_decode()
    |> Enum.map(&:public_key.pem_entry_decode/1)
    |> List.first()
  end

  defp format_list_payment_response({payments, cursor}) do
    %{payments: payments, cursor: Jason.encode!(cursor), has_more?: cursor.has_more?}
  end
end
