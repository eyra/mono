defmodule Core.NotificationCenter.Box do
  @moduledoc """
  The box type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_boxes" do
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:role_assignments, through: [:auth_node, :role_assignments])

    timestamps()
  end

  @required_fields ~w()a
  @optional_fields ~w()a
  @fields @required_fields ++ @optional_fields

  defimpl GreenLight.AuthorizationNode do
    def id(box), do: box.auth_node_id
  end

  @doc false
  def changeset(box, attrs) do
    box
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
