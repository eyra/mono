defmodule Systems.Payment.Controller do
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Frameworks.Signal
  alias Systems.Account
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
        Logger.info(
          "[Payment.Webhook] Received category=#{event.category} type=#{event.raw_type}"
        )

        route(event)
        json(conn, %{status: "ok"})

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Verification failed: #{error.message}")

        conn
        |> put_status(:unauthorized)
        |> json(%{error: error.message})
    end
  end

  # The adapter has already translated its wire format into a provider-agnostic
  # category, so routing knows nothing about any provider's event strings.
  defp route(%{category: :transaction, object_uid: uid}),
    do: handle_transaction_status_change(uid)

  defp route(%{category: :withdrawal, object_uid: uid}), do: handle_withdrawal_status_change(uid)

  defp route(%{category: :kyc, merchant_uid: merchant_uid}) when is_binary(merchant_uid),
    do: notify_kyc(merchant_uid)

  # `:ignored`, or a `:kyc` the adapter couldn't tie to a merchant — nothing to
  # act on but the raw type, which we log. The guard above keeps a merchant-less
  # KYC event from ever reaching notify_kyc/1 with a nil uid.
  defp route(%{raw_type: raw_type}),
    do: Logger.info("[Payment.Webhook] Ignoring event type=#{raw_type}")

  defp notify_kyc(merchant_uid) do
    case Account.Public.get_user_by_merchant_uid(merchant_uid) do
      %Account.User{id: user_id} ->
        Logger.info(
          "[Payment.Webhook] KYC update for user ##{user_id} (merchant #{merchant_uid})"
        )

        Signal.Public.dispatch({:payment_kyc, :updated}, %{user_id: user_id})

      nil ->
        Logger.warning("[Payment.Webhook] No user for merchant #{merchant_uid}")
    end
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

  defp apply_transaction_status(:completed, uid) do
    result = Budget.Public.complete_transaction(uid)
    Logger.info("[Payment.Webhook] Complete result: #{inspect(result)}")
  end

  defp apply_transaction_status(:failed, uid) do
    result = Budget.Public.fail_transaction(uid)
    Logger.info("[Payment.Webhook] Fail result: #{inspect(result)}")
  end

  defp apply_transaction_status(status, _uid) do
    Logger.info("[Payment.Webhook] Ignoring transaction status=#{status}")
  end

  defp handle_withdrawal_status_change(uid) do
    case Systems.Payment.Public.get_withdrawal(uid) do
      {:ok, %{status: status} = withdrawal} ->
        Logger.info("[Payment.Webhook] Provider withdrawal status=#{status} for uid=#{uid}")
        result = Systems.Fund.Public.apply_withdrawal_status(uid, withdrawal)
        Logger.info("[Payment.Webhook] Withdrawal apply result: #{inspect(result)}")

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Failed to fetch withdrawal #{uid}: #{inspect(error)}")
    end
  end
end
