defmodule BankingClient.PaymentAlias do
  use Ecto.Schema
  @primary_key false

  embedded_schema do
    field(:iban, :string)
    field(:name, :string)
  end
end
