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
    handle_event(type, uid)
  end

  defp handle_event("transaction.status_changed", uid), do: handle_transaction_status_change(uid)
  defp handle_event("transaction.status.changed", uid), do: handle_transaction_status_change(uid)

  defp handle_event(type, _uid) do
    Logger.info("[Payment.Webhook] Ignoring event type=#{type}")
  end

  defp handle_transaction_status_change(uid) do
    case Systems.Payment.Public.get_transaction(uid) do
      {:ok, %{status: status}} ->
        Logger.info("[Payment.Webhook] Provider transaction status=#{status} for uid=#{uid}")
        apply_transaction_status(status, uid)

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Failed to fetch transaction #{uid}: #{inspect(error)}")
    end
  end

  defp apply_transaction_status("completed", uid) do
    result = Budget.Public.complete_transaction(uid)
    Logger.info("[Payment.Webhook] Complete result: #{inspect(result)}")
  end

  defp apply_transaction_status("failed", uid) do
    result = Budget.Public.fail_transaction(uid)
    Logger.info("[Payment.Webhook] Fail result: #{inspect(result)}")
  end

  defp apply_transaction_status(status, _uid) do
    Logger.info("[Payment.Webhook] Ignoring transaction status=#{status}")
  end
end
