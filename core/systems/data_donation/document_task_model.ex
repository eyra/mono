defmodule Systems.DataDonation.DocumentTaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_document_tasks" do
    field(:document_ref, :string)
    timestamps()
  end

  @fields ~w(document_ref)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end
end
