defmodule Systems.Annotation.ResourceModel do
  @moduledoc """
  A module for managing annotations.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation

  schema "annotation_resource" do
    field(:value, :string)

    has_many(:references, Annotation.RefModel, foreign_key: :resource_id)
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          value: String.t()
        }

  @fields ~w(value)a
  @required_fields ~w(value)a
  @unique_fields ~w(value)a

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(@unique_fields, name: :annotation_resource_unique)
  end

  # down graph
  def preload_graph(:down), do: []

  # up graph
  def preload_graph(:up), do: [:references]
  def preload_graph(:references), do: [references: Annotation.RefModel.preload_graph(:up)]
end
