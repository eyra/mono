defmodule Link.Authorization.TestEntity do
  @moduledoc """
  An entity that is only used for test purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "test_entities" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(test_entity, attrs) do
    test_entity
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end

defmodule Link.TestHelpers do
  @moduledoc """
  Helper functions to make testing convenient.
  """
end
