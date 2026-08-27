defmodule Systems.Manual.ToolModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset

  alias Systems.Manual

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "manual_tool" do
    field(:director, Ecto.Enum, values: @tool_directors)
    belongs_to(:manual, Manual.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def changeset(model, params) do
    cast(model, params, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def ready?(tool) do
    changeset =
      tool
      |> changeset(%{})
      |> validate()

    changeset.valid?
  end

  def preload_graph(:down), do: preload_graph([:manual])
  def preload_graph(:up), do: []

  def preload_graph(:manual), do: [manual: Manual.Model.preload_graph(:down)]

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext

    def key(_), do: :manual
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-manual", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-manual", "open.cta.title")
    def ready?(tool), do: Manual.ToolModel.ready?(tool)
    def form(_, _), do: Manual.Builder.ToolForm

    def task_labels(_) do
      %{
        pending: dgettext("eyra-manual", "pending.label"),
        participated: dgettext("eyra-manual", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: true
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Utility.Module.get(director, "Director")
  end
end
