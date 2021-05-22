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
    with {:ok, data} <- Jason.decode(subscription),
         changeset <- Subscription.changeset(data),
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
    sub = %{
      endpoint: subscription.endpoint,
      expirationTime: subscription.expiration_time,
      keys: %{
        auth: subscription.auth,
        p256dh: subscription.p256dh
      }
    }

    case send_web_push(message, sub) do
      {:ok, %{status_code: 201}} -> :ok
      # not found / subscription gone
      {:ok, %{status_code: status}} when status in [404, 410] -> remove_subscription(subscription)
      response -> log_error(subscription, response)
    end
  end

  defp send_web_push(message, sub) do
    backend = Application.get_env(:core, :web_push_backend, WebPushEncryption)
    backend.send_web_push(message, sub)
  end

  defp log_error(subscription, http_response) do
    Logger.error(
      "Error when sending web-push",
      [
        subscription_id: subscription.id
      ] ++ http_response_logging_metadata(http_response)
    )
  end

  defp http_response_logging_metadata({:ok, %{status_code: status_code}}) do
    [
      http_status_code: status_code,
      reason:
        case status_code do
          400 -> "Invalid request (malformed headers)"
          413 -> "Payload size too large"
          429 -> "Rate limit hit"
          _ -> "Unexpected status code"
        end
    ]
  end

  defp http_response_logging_metadata({:error, reason}) do
    [reason: reason]
  end

  defp remove_subscription(subscription) do
    Repo.delete(subscription)
  end
end
