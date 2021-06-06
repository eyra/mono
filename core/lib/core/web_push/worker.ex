defmodule Core.WebPush.Worker do
  use Oban.Worker,
    queue: :default,
    priority: 1,
    max_attempts: 3,
    tags: ["web_push"],
    unique: [period: 30]

  alias Core.Repo
  alias Core.WebPush.PushSubscription

  @rate_limit_delay 120

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"subscription" => subscription_id, "message" => message}}) do
    backend = Application.get_env(:core, :web_push_backend, WebPushEncryption)

    subscription = Repo.get(PushSubscription, subscription_id)

    sub = %{
      endpoint: subscription.endpoint,
      expirationTime: subscription.expiration_time,
      keys: %{
        auth: subscription.auth,
        p256dh: subscription.p256dh
      }
    }

    backend.send_web_push(message, sub)
    |> process_web_push_response(subscription)
  end

  defp process_web_push_response({:ok, %{status_code: 201}}, _), do: :ok
  # not found / subscription gone
  defp process_web_push_response({:ok, %{status_code: status}}, subscription)
       when status in [404, 410] do
    Repo.delete(subscription)
  end

  defp process_web_push_response({:ok, %{status_code: 429}}, _) do
    {:snooze, @rate_limit_delay}
  end

  defp process_web_push_response({:ok, %{status_code: 413}}, _) do
    {:discard, "Payload size too large"}
  end

  defp process_web_push_response({:ok, %{status_code: 400}}, _) do
    {:discard, "Invalid request (malformed headers)"}
  end

  defp process_web_push_response({:ok, %{status_code: status}}, _) do
    {:error, "Unexpected status code: #{status}"}
  end
end
