defmodule Systems.Content.FileModel do
  @moduledoc false
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
    cast(agreement, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
end
