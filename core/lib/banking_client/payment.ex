defmodule BankingClient.Payment do
  @moduledoc false
  use Ecto.Schema

  alias BankingClient.PaymentAlias

  @primary_key false

  embedded_schema do
    field(:amount_in_cents, :integer)
    field(:date, :naive_datetime)
    field(:description, :string)
    field(:id, :integer)
    embeds_one(:payment_alias, PaymentAlias)
    embeds_one(:payment_counterparty_alias, PaymentAlias)
  end
end
