defmodule Systems.Payment.Controller do
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.Payment.Webhook
  alias Systems.Budget

  def webhook(conn, %{"provider" => provider}) do
    case Webhook.handler(provider) do
      {:ok, handler} ->
        handle_webhook(conn, handler)

      {:error, :unknown_provider} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Unknown payment provider"})
    end
  end

  defp handle_webhook(conn, handler) do
    case handler.verify_and_parse(conn) do
      {:ok, event} ->
        Logger.info("[Payment.Webhook] Received event=#{event.type} object=#{event.object_uid}")
        process_event(event)
        json(conn, %{status: "ok"})

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Verification failed: #{error.message}")

        conn
        |> put_status(:unauthorized)
        |> json(%{error: error.message})
    end
  end

  defp process_event(%{type: type, object_uid: uid} = event) do
    Logger.info("[Payment.Webhook] Processing event type=#{type} object_uid=#{uid}")
    Logger.info("[Payment.Webhook] Full event: #{inspect(event)}")

    case type do
      t when t in ["transaction.status_changed", "transaction.status.changed"] ->
        case Systems.Payment.Public.get_transaction(uid) do
          {:ok, %{status: status}} ->
            Logger.info("[Payment.Webhook] Provider transaction status=#{status} for uid=#{uid}")

            case status do
              "completed" ->
                result = Budget.Public.complete_transaction(uid)
                Logger.info("[Payment.Webhook] Complete result: #{inspect(result)}")

              "failed" ->
                result = Budget.Public.fail_transaction(uid)
                Logger.info("[Payment.Webhook] Fail result: #{inspect(result)}")

              other ->
                Logger.info("[Payment.Webhook] Ignoring transaction status=#{other}")
            end

          {:error, error} ->
            Logger.warning(
              "[Payment.Webhook] Failed to fetch transaction #{uid}: #{inspect(error)}"
            )
        end

      _ ->
        Logger.info("[Payment.Webhook] Ignoring event type=#{type}")
    end
  end
end
