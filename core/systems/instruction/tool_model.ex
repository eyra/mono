defmodule Systems.Instruction.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.Instruction

  schema "instruction_tools" do
    has_many(:assets, Instruction.AssetModel, foreign_key: :tool_id)
    has_many(:pages, Instruction.PageModel, foreign_key: :tool_id)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(repository, attrs \\ %{}) do
    repository
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(%{pages: []}), do: false
  def ready?(%{pages: [_ | _]}), do: true

  def preload_graph(:down), do: preload_graph([:assets, :pages, :auth_node])
  def preload_graph(:assets), do: [assets: Instruction.AssetModel.preload_graph(:down)]
  def preload_graph(:pages), do: [pages: Instruction.PageModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]

  defimpl Frameworks.Concept.ToolModel do
    alias Systems.Instruction
    def key(_), do: :instruction
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-instruction", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-instruction", "open.cta.title")
    def ready?(tool), do: Instruction.ToolModel.ready?(tool)
    def form(_, :fork_instruction), do: Instruction.ForkForm
    def form(_, :download_instruction), do: Instruction.DownloadForm

    def launcher(tool),
      do: %{
        module: Instruction.ToolView,
        params: %{
          tool: tool
        }
      }

    def task_labels(_) do
      %{
        pending: dgettext("eyra-instruction", "pending.label"),
        participated: dgettext("eyra-instruction", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: false
  end
end
