defmodule Systems.NextAction.Model do
  @moduledoc """
  A next action (To-do) of a user.

  `priority` is stored as an integer (`low: -10`, `normal: 0`, `high: 10`) and
  the database only accepts these values (`next_actions_priority_check`), so a
  value the code can't load is refused when it is written instead of breaking
  every list of that user's next actions. A new level needs a migration
  that widens that constraint, and two releases: first one that can read the
  new value, then one that writes it.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Systems.Account.User

  @primary_key false

  @priorities [low: -10, normal: 0, high: 10]

  schema "next_actions" do
    belongs_to(:user, User)
    field(:action, :string)
    field(:key, :string)
    field(:params, :map)
    field(:count, :integer)
    field(:priority, Ecto.Enum, values: @priorities, default: :normal)

    timestamps()
  end

  @doc false
  def changeset(next_action, attrs) do
    next_action
    |> cast(attrs, [:action, :key, :params, :priority])
    |> put_assoc(:user, Map.get(attrs, :user))
    |> validate_required([:user, :action, :priority])
    |> check_constraint(:priority, name: :next_actions_priority_check)
  end
end
