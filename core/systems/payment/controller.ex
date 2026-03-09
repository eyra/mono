defmodule Systems.Payment.Controller do
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Frameworks.Payment.Provider.OPP.Webhook

  def opp_webhook(conn, _params) do
    case Webhook.verify_and_parse(conn) do
      {:ok, event} ->
        Logger.info("[Payment.Webhook] Received event=#{event.type} object=#{event.object_uid}")
        handle_event(conn, event)

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Verification failed: #{error.message}")

        conn
        |> put_status(:unauthorized)
        |> json(%{error: error.message})
    end
  end

  defp handle_event(conn, %{type: type} = event) do
    case route_event(type, event) do
      :ok ->
        json(conn, %{status: "ok"})

      {:error, :duplicate} ->
        json(conn, %{status: "ok"})

      {:error, reason} ->
        Logger.error("[Payment.Webhook] Failed to process event=#{type}: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Processing failed"})
    end
  end

  defp route_event(type, event) do
    Logger.info(
      "[Payment.Webhook] Processing event=#{type} object_type=#{event.object_type} object_uid=#{event.object_uid}"
    )

    case type do
      "merchant." <> _ ->
        dispatch_signal({:payment_merchant, :updated}, event)

      "transaction." <> _ ->
        dispatch_signal({:payment_transaction, :updated}, event)

      "withdrawal." <> _ ->
        dispatch_signal({:payment_withdrawal, :updated}, event)

      _ ->
        Logger.warning("[Payment.Webhook] Unknown event type: #{type}")
        :ok
    end
  end

  defp dispatch_signal(signal, event) do
    Frameworks.Signal.Public.dispatch(signal, %{event: event})
  end
end
