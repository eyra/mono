defmodule Systems.Crew.TaskModel do
  @moduledoc """
  A task to be completed by a crew member.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  schema "crew_tasks" do
    field(:status, Ecto.Enum, values: [:pending, :completed])
    field(:started_at, :naive_datetime)
    field(:completed_at, :naive_datetime)
    field(:expired, :boolean)

    belongs_to(:crew, Crew.Model)
    belongs_to(:member, Crew.MemberModel)

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:status, :started_at, :completed_at, :expired])
    |> validate_required([:status])
  end
end
