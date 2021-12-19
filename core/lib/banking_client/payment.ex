defmodule BankingClient.Payment do
  use Ecto.Schema
  @primary_key false

  alias BankingClient.PaymentAlias

  embedded_schema do
    field(:amount_in_cents, :integer)
    field(:date, :naive_datetime)
    field(:description, :string)
    field(:id, :integer)
    embeds_one(:payment_alias, PaymentAlias)
    embeds_one(:payment_counterparty_alias, PaymentAlias)
  end
end
