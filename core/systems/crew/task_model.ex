defmodule Systems.Crew.TaskModel do
  @moduledoc """
  A task to be completed by a crew member.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  require Crew.RejectCategories

  schema "crew_tasks" do
    field(:identifier, {:array, :string})
    field(:status, Ecto.Enum, values: Crew.TaskStatus.values())
    field(:started_at, :naive_datetime)
    field(:completed_at, :naive_datetime)
    field(:accepted_at, :naive_datetime)
    field(:rejected_at, :naive_datetime)

    field(:expire_at, :naive_datetime)
    field(:expired, :boolean, default: false)

    field(:rejected_category, Ecto.Enum, values: Crew.RejectCategories.schema_values())
    field(:rejected_message, :string)

    belongs_to(:crew, Crew.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(identifier status started_at completed_at expire_at expired accepted_at rejected_at rejected_category rejected_message)a

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
      accepted_at: nil,
      rejected_at: nil,
      expired: false,
      expire_at: expire_at,
      rejected_category: nil,
      rejected_message: nil
    ]
  end
end
