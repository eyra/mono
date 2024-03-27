defmodule Systems.Project.ToolRefModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Frameworks.Concept

  alias Systems.Project
  alias Systems.Document
  alias Systems.Alliance
  alias Systems.Lab
  alias Systems.Feldspar
  alias Systems.Graphite
  alias Systems.Instruction

  schema "tool_refs" do
    field(:special, Ecto.Atom)

    belongs_to(:alliance_tool, Alliance.ToolModel)
    belongs_to(:lab_tool, Lab.ToolModel)
    belongs_to(:feldspar_tool, Feldspar.ToolModel)
    belongs_to(:graphite_tool, Graphite.ToolModel)
    belongs_to(:document_tool, Document.ToolModel)
    belongs_to(:instruction_tool, Instruction.ToolModel)

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
        :graphite_tool,
        :instruction_tool
      ])

  def preload_graph(:alliance_tool),
    do: [alliance_tool: Alliance.ToolModel.preload_graph(:down)]

  def preload_graph(:document_tool),
    do: [document_tool: Document.ToolModel.preload_graph(:down)]

  def preload_graph(:lab_tool), do: [lab_tool: Lab.ToolModel.preload_graph(:down)]

  def preload_graph(:feldspar_tool),
    do: [feldspar_tool: Feldspar.ToolModel.preload_graph(:down)]

  def preload_graph(:graphite_tool),
    do: [graphite_tool: Graphite.ToolModel.preload_graph(:down)]

  def preload_graph(:instruction_tool),
    do: [instruction_tool: Instruction.ToolModel.preload_graph(:down)]

  def auth_tree(%Project.ToolRefModel{} = tool_ref) do
    Concept.ToolModel.auth_tree(tool(tool_ref))
  end

  def flatten(tool_ref), do: tool(tool_ref)

  def form(%{special: special} = tool_ref), do: Concept.ToolModel.form(tool(tool_ref), special)

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
  def tool(%{graphite_tool: %{id: _id} = tool}), do: tool
  def tool(%{instruction_tool: %{id: _id} = tool}), do: tool

  def tag(%Project.ToolRefModel{special: :questionnaire}),
    do: dgettext("eyra-project", "tool_ref.tag.questionnaire")

  def tag(%Project.ToolRefModel{special: :graphite}),
    do: dgettext("eyra-project", "tool_ref.tag.graphite")

  def tag(%Project.ToolRefModel{special: _special}) do
    dgettext("eyra-project", "tool_ref.tag.default")
  end
end
