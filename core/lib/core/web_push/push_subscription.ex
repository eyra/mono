defmodule Core.WebPush.PushSubscription do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  schema "web_push_subscriptions" do
    belongs_to(:user, User)
    field(:auth, :string)
    field(:endpoint, :string)
    field(:expiration_time, :integer)
    field(:p256dh, :string)

    timestamps()
  end

  @doc false
  def changeset(push_subscription, attrs) do
    push_subscription
    |> cast(attrs, [:endpoint, :expiration_time, :auth, :p256dh])
    |> put_assoc(:user, attrs.user)
    |> validate_required([:endpoint, :auth, :p256dh])
    |> unique_constraint(:endpoint)
  end
end
