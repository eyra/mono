defmodule Systems.Feldspar.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  use Gettext, backend: CoreWeb.Gettext
  import Ecto.Changeset

  alias Systems.Workflow

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "feldspar_tools" do
    field(:archive_name, :string)
    field(:archive_ref, :string)
    field(:director, Ecto.Enum, values: @tool_directors)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:tool_ref, Workflow.ToolRefModel, foreign_key: :feldspar_tool_id)

    timestamps()
  end

  @fields ~w(archive_name archive_ref director)a
  @required_fields ~w(archive_name archive_ref)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?
  end

  def preload_graph(:down), do: preload_graph([])

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext

    alias Systems.Feldspar
    def key(_), do: :feldspar
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-feldspar", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-feldspar", "open.cta.title")
    def ready?(tool), do: Feldspar.ToolModel.ready?(tool)
    def form(_, _), do: Feldspar.ToolForm

    def launcher(tool) do
      %{
        module: Feldspar.ToolView,
        params: %{
          tool: tool
        }
      }
    end

    def task_labels(_) do
      %{
        pending: dgettext("eyra-feldspar", "pending.label"),
        participated: dgettext("eyra-feldspar", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: true
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Utility.Module.get(director, "Director")
  end
end
