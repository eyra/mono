defmodule Systems.DataDonation.DocumentTaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_document_tasks" do
    field(:document_name, :string)
    field(:document_ref, :string)
    timestamps()
  end

  @fields ~w(document_name document_ref)a
  @required_fields @fields

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(task) do
    changeset =
      changeset(task, %{})
      |> validate()

    changeset.valid?()
  end
end
