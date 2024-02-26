defmodule Systems.Content.FileModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "content_files" do
    field(:name, :string)
    field(:ref, :string)
    timestamps()
  end

  @fields ~w(name ref)a
  @required_fields ~w()a

  def changeset(agreement, attrs \\ %{}) do
    agreement
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end
end
