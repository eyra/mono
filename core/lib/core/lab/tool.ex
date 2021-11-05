defmodule Core.Lab.Tool do
  use Ecto.Schema
  use Core.Content.Node

  require Core.Enums.Themes

  import Ecto.Changeset

  schema "lab_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:time_slots, Core.Lab.TimeSlot, preload_order: [asc: :start_time])

    field(:director, Ecto.Enum, values: [:assignment])

    timestamps()
  end

  @fields []
  @required_fields []

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  defimpl GreenLight.AuthorizationNode do
    def id(lab_tool), do: lab_tool.auth_node_id
  end

  def changeset(tool, :mount, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end

defimpl Systems.Assignment.Assignable, for: Core.Lab.Tool do
  import CoreWeb.Gettext

  def languages(_), do: []
  def devices(_), do: []

  def spot_count(%{time_slots: nil}), do: 0
  def spot_count(%{time_slots: time_slots}), do: Enum.count(time_slots)
  def spot_count(_), do: 0

  def duration(_), do: 0
  def apply_label(_), do: dgettext("link-lab", "apply.cta.title")
  def open_label(_), do: dgettext("link-lab", "open.cta.title")
  def path(_, _panl_id), do: nil
end
