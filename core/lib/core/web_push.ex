defmodule Core.WebPush do
  @moduledoc """
  The WebPush context.
  """

  require Logger
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.WebPush.PushSubscription

  defmodule Keys do
    use Ecto.Schema

    embedded_schema do
      field(:auth, :string)
      field(:p256dh, :string)
    end

    def changeset(keys, data) do
      keys
      |> cast(data, [:auth, :p256dh])
      |> validate_required([:auth, :p256dh])
    end
  end

  defmodule Subscription do
    use Ecto.Schema

    embedded_schema do
      field(:endpoint, :string)
      field(:expirationTime, :integer)
      embeds_one(:keys, Keys)
    end

    def changeset(data) do
      %Subscription{}
      |> cast(data, [:endpoint, :expirationTime])
      |> cast_embed(:keys)
      |> validate_required([:endpoint, :keys])
    end
  end

  @doc """
  Send a notification to the user on all possible subscriptions.
  """
  def send(%User{} = user, message) do
    from(s in PushSubscription,
      where: s.user_id == ^user.id
    )
    |> Repo.all()
    |> Enum.each(&send_notification(&1, message))
  end

  def register(%User{} = user, subscription) do
    with changeset <- Subscription.changeset(subscription),
         {:ok, sub} <- apply_action(changeset, :update),
         changeset <-
           PushSubscription.changeset(%PushSubscription{}, %{
             user: user,
             endpoint: sub.endpoint,
             expiration_time: sub.expirationTime,
             auth: sub.keys.auth,
             p256dh: sub.keys.p256dh
           }) do
      Repo.insert(changeset,
        on_conflict: :replace_all,
        conflict_target: :endpoint
      )
    end
  end

  defp send_notification(subscription, message) do
    %{subscription: subscription.id, message: message}
    |> Core.WebPush.Worker.new()
    |> Oban.insert()
  end
end
