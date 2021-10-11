defmodule Systems.NextAction.Model do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User
  alias Core.Content.Node

  @primary_key false

  schema "next_actions" do
    belongs_to(:user, User)
    field(:action, :string)
    belongs_to(:content_node, Node)
    field(:params, :map)
    field(:count, :integer)

    timestamps()
  end

  @doc false
  def changeset(next_action, attrs) do
    next_action
    |> cast(attrs, [:action, :params])
    |> put_assoc(:user, Map.get(attrs, :user))
    |> put_assoc(:content_node, Map.get(attrs, :content_node))
    |> validate_required([:user, :action])
  end
end
