defmodule Systems.Budget.DepositModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Budget.DepositModel

  @primary_key false

  embedded_schema do
    field(:amount, :string)
    field(:reference, :string)
  end

  @fields ~w(amount reference)a
  @required_fields @fields

  def changeset(%DepositModel{} = deposit), do: change(deposit)

  def changeset(amount, reference) do
    %__MODULE__{}
    |> cast(%{amount: amount, reference: reference}, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:amount, ~r/^[0-9]*$/)
  end
end
