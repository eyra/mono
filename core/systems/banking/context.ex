defmodule Systems.Banking.Context do
  @type account :: %{id: binary(), name: binary()}
  @type transaction :: %{
          from: account(),
          to: account(),
          amount: integer(),
          date: DateTime.t(),
          description: binary()
        }

  @spec list_payments(since :: binary() | nil) :: %{
          marker: binary(),
          transactions: list(transaction()),
          has_more: boolean()
        }
  def list_payments(since) when is_nil(since) or is_binary(since) do
    backend().list_payments(since)
  end

  @spec submit_payment(
          payment :: %{
            idempotence_key: binary(),
            to: account(),
            amount: integer(),
            description: binary()
          }
        ) :: :ok
  def submit_payment(payment) do
    backend().submit_payment(payment)
  end

  def backend do
    Application.fetch_env!(:core, :banking_backend)
  end
end
