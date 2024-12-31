defmodule Systems.Onyx.ToolModel do
  use Gettext, backend: CoreWeb.Gettext
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "onyx_tool" do
    field(:director, Ecto.Enum, values: @tool_directors)

    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:associated_files, Onyx.ToolFileAssociation, foreign_key: :tool_id)
    has_many(:criterion_groups, Onyx.CriterionGroupModel, foreign_key: :tool_id)

    timestamps()
  end

  @fields ~w(director)a
  @required_fields @fields

  def changeset(tool, attrs) do
    cast(tool, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:auth_node, :associated_files, :criterion_groups])
  def preload_graph(:up), do: preload_graph([])
  def preload_graph(:auth_node), do: [auth_node: [:role_assignments]]

  def preload_graph(:associated_files),
    do: [associated_files: Onyx.ToolFileAssociation.preload_graph(:down)]

  def preload_graph(:criterion_groups),
    do: [criterion_groups: Onyx.CriterionGroupModel.preload_graph(:down)]

  def ready?(%{name: nil}), do: false
  def ready?(%{image_id: nil}), do: false
  def ready?(%{associated_papers: []}), do: false
  def ready?(%{criterion_groups: []}), do: false
  def ready?(_), do: true

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext
    alias Systems.Onyx
    def key(_), do: :onyx
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-onyx", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-onyx", "open.cta.title")
    def ready?(tool), do: Onyx.ToolModel.ready?(tool)
    def form(_, _), do: Onyx.ToolForm

    def launcher(tool),
      do: %{
        module: Onyx.ToolView,
        params: %{
          tool: tool
        }
      }

    def task_labels(_) do
      %{
        pending: dgettext("eyra-onyx", "pending.label"),
        participated: dgettext("eyra-onyx", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: false
  end

  defimpl Frameworks.Concept.Leaf do
    use Gettext, backend: CoreWeb.Gettext
    alias Frameworks.Concept
    def resource_id(%{id: id}), do: "onyx/#{id}"
    def tag(_), do: dgettext("eyra-onyx", "leaf.tag")

    def info(%{associated_papers: associated_papers}, _timezone) do
      paper_count = associated_papers |> length()
      [dngettext("eyra-onyx", "1 paper", "* papers", paper_count)]
    end

    def status(_), do: %Concept.Leaf.Status{value: :private}
  end
end
