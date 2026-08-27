defmodule Systems.Zircon.Screening.ToolAnnotationAssoc do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Annotation
  alias Systems.Zircon.Screening

  schema "zircon_screening_tool_annotation" do
    belongs_to(:tool, Screening.ToolModel)
    belongs_to(:annotation, Annotation.Model)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(association, attrs) do
    cast(association, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: []

  def preload_graph(:up), do: [tool: preload_graph(:tool), annotation: preload_graph(:annotation)]

  def preload_graph(:tool), do: [tool: Screening.ToolModel.preload_graph(:up)]
  def preload_graph(:annotation), do: [annotation: Annotation.Model.preload_graph(:up)]
end
