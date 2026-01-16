defmodule Systems.Storage.PendingBlobModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(data)a
  @required_fields @fields

  schema "storage_pending_blobs" do
    field(:data, :binary)
    timestamps()
  end

  def changeset(blob, attrs) do
    blob
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def prepare(data) when is_binary(data) do
    %__MODULE__{}
    |> changeset(%{data: data})
    |> validate()
  end
end
