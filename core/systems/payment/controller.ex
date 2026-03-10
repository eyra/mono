defmodule Systems.Payment.Controller do
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.Payment.Webhook

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
        json(conn, %{status: "ok"})

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Verification failed: #{error.message}")

        conn
        |> put_status(:unauthorized)
        |> json(%{error: error.message})
    end
  end
end
