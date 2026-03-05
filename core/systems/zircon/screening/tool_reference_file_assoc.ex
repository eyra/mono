defmodule Systems.Zircon.Screening.ToolReferenceFileAssoc do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Paper
  alias Systems.Zircon.Screening

  schema "zircon_screening_tool_reference_file" do
    belongs_to(:tool, Screening.ToolModel)
    belongs_to(:reference_file, Paper.ReferenceFileModel)

    timestamps()
  end

  @fields ~w()
  @required_fields @fields

  def changeset(association, attrs) do
    cast(association, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph(:reference_file)
  def preload_graph(:up), do: preload_graph(:tool)

  def preload_graph(:tool), do: [tool: Screening.ToolModel.preload_graph(:up)]

  def preload_graph(:reference_file), do: [reference_file: Paper.ReferenceFileModel.preload_graph(:down)]
end
