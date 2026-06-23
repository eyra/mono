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

  defp process_event(%{type: type, object_uid: uid, object_type: object_type} = event) do
    Logger.info("[Payment.Webhook] Processing event type=#{type} object_uid=#{uid}")
    Logger.info("[Payment.Webhook] Full event: #{inspect(event)}")

    if kyc_event?(type, object_type) do
      handle_kyc_change(event)
    else
      handle_event(type, uid)
    end
  end

  # OPP's exact bank-account/merchant event-type strings vary; match on either the
  # object_type or a type prefix so a KYC status change is never missed.
  defp kyc_event?(type, object_type) do
    object_type in ["bank_account", "merchant"] or
      String.starts_with?(type, "bank_account") or
      String.starts_with?(type, "merchant")
  end

  # A bank-account event's owning merchant is the parent; a merchant event is itself.
  defp handle_kyc_change(%{object_type: "merchant", object_uid: merchant_uid}),
    do: notify_kyc(merchant_uid)

  defp handle_kyc_change(%{parent_type: "merchant", parent_uid: merchant_uid})
       when is_binary(merchant_uid),
       do: notify_kyc(merchant_uid)

  defp handle_kyc_change(%{object_uid: merchant_uid} = event) do
    case String.starts_with?(event.type, "merchant") do
      true -> notify_kyc(merchant_uid)
      false -> Logger.warning("[Payment.Webhook] KYC event without merchant: #{inspect(event)}")
    end
  end

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

  defp handle_event("transaction.status_changed", uid), do: handle_transaction_status_change(uid)
  defp handle_event("transaction.status.changed", uid), do: handle_transaction_status_change(uid)

  defp handle_event("withdrawal.status_changed", uid), do: handle_withdrawal_status_change(uid)
  defp handle_event("withdrawal.status.changed", uid), do: handle_withdrawal_status_change(uid)

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

  defp handle_withdrawal_status_change(uid) do
    case Systems.Payment.Public.get_withdrawal(uid) do
      {:ok, %{status: status}} ->
        Logger.info("[Payment.Webhook] Provider withdrawal status=#{status} for uid=#{uid}")
        result = Systems.Fund.Public.apply_withdrawal_status(uid, status)
        Logger.info("[Payment.Webhook] Withdrawal apply result: #{inspect(result)}")

      {:error, error} ->
        Logger.warning("[Payment.Webhook] Failed to fetch withdrawal #{uid}: #{inspect(error)}")
    end
  end
end
