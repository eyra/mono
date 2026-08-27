defmodule Systems.Content.RepositoryModel do
  @moduledoc false
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
    cast(repository, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
end
