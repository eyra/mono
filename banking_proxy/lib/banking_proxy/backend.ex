defmodule BankingProxy.BankingBackend do
  @opaque cursor :: map()
  @type payment_alias :: %{
          name: binary(),
          iban: binary()
        }
  @type payment :: %{
          payment_alias: payment_alias(),
          payment_counterparty_alias: payment_alias(),
          amount_in_cents: integer(),
          description: binary(),
          date: NaiveDateTime.t(),
          id: integer()
        }

  @type transaction :: %{
          amount_in_cents: pos_integer(),
          to_iban: binary(),
          to_name: binary(),
          description: binary()
        }

  @type list_payments_result :: {list(payment()), cursor()}

  # @callback connect() :: :ok
  # @callback connect(serialized :: binary()) :: :ok

  @callback serialize_connection() :: binary()

  @callback list_payments() :: list_payments_result()
  @callback list_payments(cursor()) :: list_payments_result()

  @callback submit_payment(transaction()) :: :ok | {:error, binary()}
end
