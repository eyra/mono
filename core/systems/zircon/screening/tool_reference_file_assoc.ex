defmodule Systems.Zircon.Screening.ToolReferenceFileAssoc do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Zircon.Screening
  alias Systems.Paper

  schema "zircon_screening_tool_reference_file" do
    belongs_to(:tool, Screening.ToolModel)
    belongs_to(:reference_file, Paper.ReferenceFileModel)

    timestamps()
  end

  @fields ~w()
  @required_fields @fields

  def changeset(association, attrs) do
    association
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: [
    tool: preload_graph(:tool),
    reference_file: preload_graph(:reference_file)
  ]

  def preload_graph(:tool), do: [tool: Screening.ToolModel.preload_graph(:up)]
  def preload_graph(:reference_file), do: [reference_file: Paper.ReferenceFileModel.preload_graph(:up)]
end
