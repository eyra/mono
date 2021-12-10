defmodule Systems.NextAction.Model do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  @primary_key false

  schema "next_actions" do
    belongs_to(:user, User)
    field(:action, :string)
    field(:key, :string)
    field(:params, :map)
    field(:count, :integer)

    timestamps()
  end

  @doc false
  def changeset(next_action, attrs) do
    next_action
    |> cast(attrs, [:action, :key, :params])
    |> put_assoc(:user, Map.get(attrs, :user))
    |> validate_required([:user, :action])
  end
end
