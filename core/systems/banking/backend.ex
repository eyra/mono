defmodule Systems.Banking.Backend do
  alias Systems.Banking
  alias Systems.Banking.Transaction

  @type account :: Banking.account()
  @type payment :: Banking.payment()
  @callback list_payments(since :: binary() | nil) :: %{
              marker: binary(),
              payments: list(Transaction.t()),
              has_more: boolean()
            }
  @callback submit_payment(
              payment :: %{
                idempotence_key: binary(),
                from: account(),
                to: account(),
                amount: integer(),
                description: binary()
              }
            ) :: :ok | {:error, term()}
  @callback start_link(account :: binary()) :: GenServer.on_start()
end
