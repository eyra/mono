defmodule Systems.Lab.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Model

  require Core.Enums.Themes

  import Ecto.Changeset

  schema "lab_tools" do
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:time_slots, Systems.Lab.TimeSlotModel, foreign_key: :tool_id, preload_order: [asc: :start_time])

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w(director)a

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(lab_tool), do: lab_tool.auth_node_id
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end
end
