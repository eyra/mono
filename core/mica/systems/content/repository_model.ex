defmodule Systems.Content.RepositoryModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "content_repositories" do
    field(:platform, Ecto.Enum, values: [:github])
    field(:url, :string)
    timestamps()
  end

  @fields ~w(platform url)a
  @required_fields @fields

  def changeset(repository, attrs \\ %{}) do
    repository
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
end
