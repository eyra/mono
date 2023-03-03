defmodule Systems.Banking.Backend do
  alias Systems.Banking

  @type account :: Banking.Public.account()

  @type payment :: %{
          idempotence_key: binary(),
          from: account(),
          to: account(),
          amount: integer(),
          description: binary()
        }

  @callback list_payments(since :: binary() | nil) :: %{
              cursor: binary(),
              payments: list(payment),
              has_more?: boolean()
            }
  @callback submit_payment(payment) :: :ok | {:error, term()}
end
