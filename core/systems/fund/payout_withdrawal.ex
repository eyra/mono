defmodule Systems.Fund.PayoutWithdrawal do
  @moduledoc """
  The withdrawal leg of a payout, and its recovery.

  A payout is a two-leg saga: `Fund.Public` transfers the money from the platform
  merchant to the participant's merchant, then hands the payout here to withdraw
  it from there to the participant's bank. This module owns the second leg —
  issuing the withdrawal on the happy path (`issue/3`), and driving a stranded
  payout forward afterwards (`resume/1`).

  Nothing here re-moves money. Recovery in particular never blind-replays: the
  provider's idempotency keys only de-duplicate for a short window, so instead of
  re-issuing a leg and hoping it de-dupes, it asks the provider what actually
  happened and acts on that.
  """
  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Fund
  alias Systems.Payment

  @doc """
  Issue the withdrawal for a payout whose funds are already on the participant's
  merchant, recording the provider uid.

  A provider error is not reverted: the money has moved, so the payout is left
  `:pending` for reconciliation rather than unwound.
  """
  def issue(%Fund.PayoutModel{} = payout, merchant_uid, total) do
    attrs = %{amount: total, description: "Reward payout"}

    case Payment.Public.create_withdrawal(
           merchant_uid,
           :EUR,
           attrs,
           Fund.PayoutModel.withdrawal_key(payout)
         ) do
      {:ok, withdrawal} ->
        record_uid(payout, withdrawal, total)

      {:error, reason} ->
        # Funds already on the participant merchant — don't revert; reconciliation completes it.
        Logger.error(
          "[Fund] transfer succeeded but withdrawal failed for payout #{payout.id}; " <>
            "left :pending for reconciliation: #{inspect(reason)}"
        )

        {:error, {:opp_failed, reason}}
    end
  end

  @doc """
  Drive a stranded payout forward, without ever re-moving money.

  Shared entrypoint for the "Retry payout" button and the reconciliation worker.
  Dispatches on `PayoutModel.phase/1`:

  * `:awaiting_withdrawal` — the money is on the participant's merchant but no
    withdrawal uid was recorded. Look for a withdrawal already at the provider
    (its `reference` carries the payout's key); adopt it if found, otherwise
    issue one.
  * `:withdrawal_retryable` — a withdrawal was rejected after the money moved.
    Issue a fresh one under a new attempt (a rejected withdrawal keeps its key).
  * `:awaiting_provider` — issued and in flight; nothing to do.
  * `:completed` / `:failed` — terminal; nothing to do.
  * `:awaiting_transfer` — the transfer was never confirmed and a charge cannot
    be looked up at the provider, so we cannot tell whether the money moved.
    Re-driving risks a double charge; this is the one case left for a human.
  """
  def resume(%Fund.PayoutModel{} = payout) do
    resume_by_phase(Fund.PayoutModel.phase(payout), payout)
  end

  defp resume_by_phase(:awaiting_withdrawal, payout), do: resume_withdrawal(payout)
  defp resume_by_phase(:withdrawal_retryable, payout), do: retry_withdrawal(payout)
  defp resume_by_phase(:awaiting_provider, payout), do: {:ok, {:in_flight, payout}}
  defp resume_by_phase(:completed, payout), do: {:ok, {:resolved, payout}}
  defp resume_by_phase(:failed, payout), do: {:ok, {:resolved, payout}}

  defp resume_by_phase(:awaiting_transfer, %Fund.PayoutModel{id: id}) do
    Logger.error(
      "[Fund] payout ##{id} has an unconfirmed transfer and no findable charge — manual review"
    )

    {:error, :manual_review}
  end

  # Funds committed, no withdrawal uid recorded. Either a withdrawal was created
  # and we lost the response, or none was ever created. List-and-match tells the
  # two apart safely; issuing blindly would double-withdraw in the first case.
  defp resume_withdrawal(%Fund.PayoutModel{amount_cents: total} = payout) do
    merchant_uid = merchant_uid_for(payout)

    case find_existing_withdrawal(payout, merchant_uid) do
      {:ok, withdrawal} -> adopt_withdrawal(payout, withdrawal, total)
      :none -> issue(payout, merchant_uid, total)
      {:error, _} = error -> error
    end
  end

  # The current withdrawal is terminally failed but the money is still on the
  # participant's merchant. A rejected withdrawal keeps its idempotency key, so
  # the retry runs under a fresh attempt.
  defp retry_withdrawal(%Fund.PayoutModel{amount_cents: total} = payout) do
    merchant_uid = merchant_uid_for(payout)

    with {:ok, payout} <- next_withdrawal_attempt(payout) do
      issue(payout, merchant_uid, total)
    end
  end

  defp find_existing_withdrawal(%Fund.PayoutModel{} = payout, merchant_uid) do
    prefix = Fund.PayoutModel.withdrawal_key_prefix(payout)

    case Payment.Public.list_withdrawals(merchant_uid) do
      {:ok, withdrawals} ->
        withdrawals
        |> Enum.find(fn %{reference: ref} ->
          is_binary(ref) and String.starts_with?(ref, prefix)
        end)
        |> case do
          nil -> :none
          withdrawal -> {:ok, withdrawal}
        end

      {:error, _} = error ->
        error
    end
  end

  # A withdrawal already existed; we just never recorded it. Persist its uid, then
  # apply whatever status it already carries (it may be terminal).
  defp adopt_withdrawal(%Fund.PayoutModel{} = payout, %{uid: uid} = withdrawal, total) do
    with {:ok, _result} <- record_uid(payout, withdrawal, total) do
      Fund.Public.apply_withdrawal_status(uid, withdrawal)
    end
  end

  defp next_withdrawal_attempt(%Fund.PayoutModel{withdrawal_attempt: attempt} = payout) do
    payout
    |> Fund.PayoutModel.changeset(%{
      withdrawal_attempt: attempt + 1,
      provider_uid: nil,
      status: :pending,
      failure_reason: nil
    })
    |> Repo.update()
  end

  defp record_uid(payout, %{uid: uid} = withdrawal, total) do
    case payout |> Fund.PayoutModel.changeset(%{provider_uid: uid}) |> Repo.update() do
      {:ok, payout} ->
        {:ok, %{payout: payout, withdrawal: withdrawal, amount: total}}

      {:error, _changeset} ->
        # Withdrawal exists at the provider but uid unsaved — don't revert;
        # reconciliation recovers it by its reference.
        Logger.error(
          "[Fund] withdrawal #{uid} created but provider_uid not persisted for " <>
            "payout #{payout.id}; left :pending for reconciliation"
        )

        {:ok, %{payout: payout, withdrawal: withdrawal, amount: total}}
    end
  end

  defp merchant_uid_for(%Fund.PayoutModel{user_id: user_id}) do
    %Account.User{merchant_uid: merchant_uid} = Account.Public.get_user!(user_id)
    merchant_uid
  end
end
