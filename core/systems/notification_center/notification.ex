defmodule Systems.NotificationCenter.Notification do
  @moduledoc """
  The notification type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field(:title, :string)
    field(:action, :string)
    field(:status, Ecto.Enum, values: [:new, :read, :archived], default: :new)

    belongs_to(:box, Systems.NotificationCenter.Box)

    timestamps()
  end

  @required_fields ~w(title status)a
  @optional_fields ~w(action status)a
  @fields @required_fields ++ @optional_fields

  defimpl GreenLight.AuthorizationNode do
    def id(notification), do: notification.auth_node_id
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
