defmodule Systems.NextAction.Model do
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
  end
end
