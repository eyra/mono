defmodule Core.Lab.Tool do
  use Ecto.Schema
  use Core.Content.Node

  require Core.Enums.Themes

  import Ecto.Changeset

  alias Core.Studies.Study
  alias Core.Accounts.User
  alias Core.Promotions.Promotion

  schema "lab_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:study, Study)
    belongs_to(:promotion, Promotion)

    has_many(:time_slots, Core.Lab.TimeSlot, preload_order: [asc: :start_time])
    many_to_many(:participants, User, join_through: :lab_reservations)

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
    |> cast(params, @fields)
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end
