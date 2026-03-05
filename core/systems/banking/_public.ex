defmodule Systems.Banking.Public do
  @moduledoc false
  use Core, :public

  alias Systems.Banking

  require Logger

  @spec submit_payment(
          payment :: %{
            idempotence_key: binary(),
            to_iban: binary(),
            account: account(),
            amount: integer(),
            description: binary()
          }
        ) :: :ok
  def submit_payment(%{
        idempotence_key: idempotence_key,
        to_iban: to,
        account: _account,
        amount: amount,
        description: description
      }) do
    backend().submit_payment(%{
      idempotence_key: idempotence_key,
      to: to,
      amount: amount,
      description: "#{description}"
    })
  end

  @type account :: %{id: binary(), name: binary()}
  @type transaction :: %{
          from: account(),
          to: account(),
          amount: integer(),
          date: DateTime.t(),
          description: binary()
        }

  @spec list_payments(since :: binary() | nil) :: %{
          cursor: binary(),
          payments: list(transaction()),
          has_more: boolean()
        }
  def list_payments(since) when is_nil(since) or is_binary(since) do
    backend().list_payments(since)
  end

  def is_live?(currency) when is_atom(currency) do
    is_live?(Atom.to_string(currency))
  end

  def is_live?(currency) when is_binary(currency) do
    Enum.member?(Banking.Supervisor.currencies(), currency)
  end

  def backend do
    Application.fetch_env!(:core, :banking_backend)
  end
end
