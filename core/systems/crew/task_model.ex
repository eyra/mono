defmodule Systems.Crew.TaskModel do
  @moduledoc """
  A task to be completed by a crew member.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  schema "crew_tasks" do
    field(:status, Ecto.Enum, values: [:pending, :completed])
    field(:plugin, Ecto.Enum, values: [:online_study])

    belongs_to(:crew, Crew.Model)
    belongs_to(:member, Crew.MemberModel)

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:status, :plugin])
    |> validate_required([:status, :plugin])
  end
end
