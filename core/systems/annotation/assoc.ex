defmodule Systems.Annotation.Assoc do
  @moduledoc """
  A module for associating an annotation with an annotation reference   .
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation

  schema "annotation_assoc" do
    belongs_to(:annotation, Annotation.Model)
    belongs_to(:ref, Annotation.Ref)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def changeset(assoc, attrs) do
    assoc
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:ref]
  def preload_graph(:up), do: [:annotation]

  def preload_graph(:annotation), do: [annotation: Annotation.Model.preload_graph(:up)]
  def preload_graph(:ref), do: [ref: Annotation.Ref.preload_graph(:down)]
end

