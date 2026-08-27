defmodule Systems.Assignment.ParticipationModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Assignment

  schema "assignment_participation" do
    belongs_to(:user, Account.User)
    belongs_to(:assignment, Assignment.Model)

    field(:completed_at, :naive_datetime)
    field(:accepted_at, :naive_datetime)
    field(:rejected_at, :naive_datetime)
    field(:rejected_message, :string)

    timestamps()
  end

  @fields ~w(completed_at accepted_at rejected_at rejected_message)a

  def changeset(participation, attrs) do
    cast(participation, attrs, @fields)
  end

  def validate(changeset) do
    unique_constraint(changeset, [:user_id, :assignment_id],
      name: :assignment_participation_unique
    )
  end

  def preload_graph(:up), do: []

  def preload_graph(:down),
    do: [assignment: preload_graph(:assignment), user: preload_graph(:user)]

  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]
  def preload_graph(:user), do: [user: []]
end
