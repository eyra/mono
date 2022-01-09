defmodule BankingClient.ListPaymentsResponse do
  use Ecto.Schema
  import Ecto.Changeset
  alias BankingClient.Payment
  @primary_key false

  embedded_schema do
    field(:cursor, :string)
    field(:has_more?, :boolean)
    embeds_many(:payments, Payment)
  end

  def conform(data) do
    changeset(%__MODULE__{}, data)
    |> apply_action!(:update)
  end

  def changeset(schema, data) do
    schema
    |> cast(data, [:cursor, :has_more?])
    |> cast_embed(:payments, with: &payment_changeset/2)
  end

  defp payment_changeset(schema, params) do
    schema
    |> cast(params, [:amount_in_cents, :date, :description, :id])
    |> cast_embed(:payment_alias, with: &payment_alias_changeset/2)
    |> cast_embed(:payment_counterparty_alias, with: &payment_alias_changeset/2)
  end

  defp payment_alias_changeset(schema, params) do
    schema
    |> cast(params, [:iban, :name])
  end
end
