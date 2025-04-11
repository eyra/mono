defmodule Systems.Lab.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Model
  use Frameworks.Utility.Schema

  require Core.Enums.Themes

  import Ecto.Changeset
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Lab
  alias Systems.Workflow

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "lab_tools" do
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:tool_ref, Workflow.ToolRefModel, foreign_key: :lab_tool_id)

    has_many(:time_slots, Lab.TimeSlotModel,
      foreign_key: :tool_id,
      preload_order: [asc: :start_time],
      on_delete: :delete_all
    )

    field(:director, Ecto.Enum, values: @tool_directors)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w(director)a

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  def preload_graph(:down),
    do:
      preload_graph([
        :auth_node,
        :time_slots
      ])

  def preload_graph(:auth_node), do: [auth_node: []]
  def preload_graph(:time_slots), do: [time_slots: []]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(lab_tool), do: lab_tool.auth_node_id
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> changeset(params)
    |> validate()
  end

  def changeset(tool, _, params) do
    tool
    |> changeset(params)
    |> cast(params, [:director])
  end

  def changeset(tool, params) do
    tool
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

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext

    alias Systems.Lab
    def key(_), do: :lab
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("link-lab", "apply.cta.title")
    def open_label(_), do: dgettext("link-lab", "open.cta.title")
    def ready?(tool), do: Lab.ToolModel.ready?(tool)
    def form(_, _), do: Lab.Form
    def launcher(_), do: nil

    def task_labels(_) do
      %{
        pending: dgettext("link-lab", "pending.label"),
        participated: dgettext("link-lab", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: true
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Utility.Module.get(director, "Director")
  end
end
