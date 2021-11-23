defmodule Systems.Crew.TaskModel do
  @moduledoc """
  A task to be completed by a crew member.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Crew

  require Crew.RejectCategories

  schema "crew_tasks" do
    field(:status, Ecto.Enum, values: [:pending, :completed, :accepted, :rejected])
    field(:started_at, :naive_datetime)
    field(:completed_at, :naive_datetime)
    field(:accepted_at, :naive_datetime)
    field(:rejected_at, :naive_datetime)

    field(:expire_at, :naive_datetime)
    field(:expired, :boolean)

    field(:rejected_category, Ecto.Enum, values: Crew.RejectCategories.schema_values())
    field(:rejected_message, :string)

    belongs_to(:crew, Crew.Model)
    belongs_to(:member, Crew.MemberModel)

    timestamps()
  end

  @fields ~w(status started_at completed_at expire_at expired accepted_at rejected_at rejected_category rejected_message)a

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, @fields)
    |> validate_required([:status])
  end
end
