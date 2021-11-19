defmodule Systems.Banking.Backend do
  alias Systems.Banking

  @type account :: Banking.Context.account()

  @type payment :: %{
    idempotence_key: binary(),
    from: account(),
    to: account(),
    amount: integer(),
    description: binary()
  }

  @callback list_payments(since :: binary() | nil) :: %{
              marker: binary(),
              payments: list(payment),
              has_more: boolean()
            }
  @callback submit_payment(payment) :: :ok | {:error, term()}
  @callback start_link(account :: binary()) :: GenServer.on_start()
end
