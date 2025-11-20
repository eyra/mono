defmodule Core.Authentication.Entity do
  @moduledoc """
  Entity is a representation of an entity that can be authenticated.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  @type t :: %__MODULE__{
          identifier: String.t()
        }

  schema "authentication_entity" do
    field(:identifier, :string)
    timestamps()
  end

  @fields ~w(identifier)a
  @required_fields @fields

  def change(entity, attrs \\ %{}) do
    entity
    |> Changeset.cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> Changeset.validate_required(@required_fields)
    |> Changeset.unique_constraint(:identifier, name: :authentication_entity_unique)
  end
end
