defmodule Systems.Assignment.InstanceModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Assignment
  alias Systems.Account

  schema "assignment_instance" do
    belongs_to(:user, Account.User)
    belongs_to(:assignment, Assignment.Model)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w(panel_info)a

  def changeset(instance, attrs) do
    instance
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :assignment_id], name: :assignment_instance_unique)
  end

  def preload_graph(:up), do: []

  def preload_graph(:down),
    do: [
      assignment: preload_graph(:assignment),
      user: preload_graph(:user)
    ]

  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]
  def preload_graph(:user), do: [user: []]
end
