defmodule Systems.Project.ToolRefModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Frameworks.Concept

  alias Systems.{
    Project,
    Document,
    Alliance,
    Lab,
    Feldspar,
    Benchmark
  }

  schema "tool_refs" do
    field(:special, Ecto.Atom)

    belongs_to(:alliance_tool, Alliance.ToolModel)
    belongs_to(:lab_tool, Lab.ToolModel)
    belongs_to(:feldspar_tool, Feldspar.ToolModel)
    belongs_to(:benchmark_tool, Benchmark.ToolModel)
    belongs_to(:document_tool, Document.ToolModel)

    has_one(:item, Project.ItemModel, foreign_key: :tool_ref_id)

    timestamps()
  end

  @required_fields ~w(special)a
  @fields @required_fields

  @doc false
  def changeset(tool_ref, attrs) do
    tool_ref
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :alliance_tool,
        :document_tool,
        :lab_tool,
        :feldspar_tool,
        :benchmark_tool
      ])

  def preload_graph(:alliance_tool),
    do: [alliance_tool: Alliance.ToolModel.preload_graph(:down)]

  def preload_graph(:document_tool),
    do: [document_tool: Document.ToolModel.preload_graph(:down)]

  def preload_graph(:lab_tool), do: [lab_tool: Lab.ToolModel.preload_graph(:down)]

  def preload_graph(:feldspar_tool),
    do: [feldspar_tool: Feldspar.ToolModel.preload_graph(:down)]

  def preload_graph(:benchmark_tool),
    do: [benchmark_tool: Benchmark.ToolModel.preload_graph(:down)]

  def auth_tree(%Project.ToolRefModel{} = tool_ref) do
    Concept.ToolModel.auth_tree(tool(tool_ref))
  end

  def flatten(item), do: tool(item)

  def external_path(%{alliance_tool: alliance_tool}, next_id) do
    Alliance.ToolModel.external_path(alliance_tool, next_id)
  end

  def external_path(_, _), do: nil

  def tool_field(tool), do: String.to_existing_atom("#{Concept.ToolModel.key(tool)}_tool")
  def tool_id_field(tool), do: String.to_existing_atom("#{Concept.ToolModel.key(tool)}_tool_id")

  def tool(%{alliance_tool: %{id: _id} = tool}), do: tool
  def tool(%{feldspar_tool: %{id: _id} = tool}), do: tool
  def tool(%{document_tool: %{id: _id} = tool}), do: tool
  def tool(%{lab_tool: %{id: _id} = tool}), do: tool
  def tool(%{benchmark_tool: %{id: _id} = tool}), do: tool
end
