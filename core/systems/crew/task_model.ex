defmodule Systems.Crew.TaskModel do
  @moduledoc """
  A task to be completed by a crew member.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  schema "crew_tasks" do
    field(:identifier, {:array, :string})
    field(:status, Ecto.Enum, values: Crew.TaskStatus.values())
    field(:started_at, :naive_datetime)
    field(:completed_at, :naive_datetime)

    field(:expire_at, :naive_datetime)
    field(:expired, :boolean, default: false)

    belongs_to(:crew, Crew.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(identifier status started_at completed_at expire_at expired)a

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(task), do: task.auth_node_id
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, @fields)
    |> validate_required([:identifier, :status])
    |> unique_constraint(:identifier)
  end

  def reset_attrs(expire_at) do
    [
      status: :pending,
      started_at: nil,
      completed_at: nil,
      expired: false,
      expire_at: expire_at
    ]
  end
end
