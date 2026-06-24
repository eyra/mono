defmodule Systems.Payment.ControllerTest do
  @moduledoc """
  Integration tests for `Systems.Payment.Controller.webhook/2` — focused on
  the `"withdrawal.status.changed"` dispatch added for UC-OPP-06 MS.11.

  Signature verification is covered by `Systems.Payment.Provider.OPP.WebhookTest`;
  here we set `:skip_webhook_verification` so the assertions stay on the
  routing + downstream-effect side of the controller.
  """
  use CoreWeb.ConnCase, async: false
  import Mox

  alias Core.Factories
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  @moduletag :capture_log

  setup :verify_on_exit!

  setup do
    Application.put_env(:core, :skip_webhook_verification, true)

    on_exit(fn ->
      Application.put_env(:core, :skip_webhook_verification, false)
    end)

    currency = Fund.Factories.create_currency("ctrl_currency", :legal, "ƒ", 2)
    fund = Fund.Factories.create_fund("ctrl_fund", currency)
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_ctrl"})

    {:ok, fund: fund, user: user}
  end

  defp insert_pending_payout(user, fund, amount, provider_uid) do
    payout =
      Core.Repo.insert!(%Fund.PayoutModel{
        user_id: user.id,
        amount_cents: amount,
        currency: "eur",
        status: :pending,
        provider_uid: provider_uid
      })

    reward =
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: amount,
        status: :pending_payout,
        payout_id: payout.id,
        idempotence_key: "ctrl-#{System.unique_integer([:positive])}"
      })

    {payout, reward}
  end

  defp post_webhook(conn, type, object_uid) do
    body = %{
      "uid" => "notif_#{System.unique_integer([:positive])}",
      "type" => type,
      "object_uid" => object_uid,
      "object_type" => "withdrawal",
      "object_url" => "https://example.test/v1/withdrawals/#{object_uid}"
    }

    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> post(~p"/api/payment/webhook/opp", Jason.encode!(body))
  end

  describe "POST /api/payment/webhook/opp — withdrawal.status.changed" do
    test ~s(routes "completed" to Fund.Public and transitions payout + rewards),
         %{conn: conn, fund: fund, user: user} do
      {payout, reward} = insert_pending_payout(user, fund, 1000, "w_ctrl_completed")

      expect(ProviderMock, :get_withdrawal, fn "w_ctrl_completed" ->
        {:ok, %{uid: "w_ctrl_completed", status: "completed", amount: 1000}}
      end)

      conn = post_webhook(conn, "withdrawal.status.changed", "w_ctrl_completed")

      assert json_response(conn, 200) == %{"status" => "ok"}
      assert %{status: :completed} = Core.Repo.reload!(payout)
      assert %{status: :paid} = Core.Repo.reload!(reward)
    end

    test ~s(routes the underscore variant "withdrawal.status_changed" OPP actually sends),
         %{conn: conn, fund: fund, user: user} do
      {payout, reward} = insert_pending_payout(user, fund, 1000, "w_ctrl_underscore")

      expect(ProviderMock, :get_withdrawal, fn "w_ctrl_underscore" ->
        {:ok, %{uid: "w_ctrl_underscore", status: "completed", amount: 1000}}
      end)

      conn = post_webhook(conn, "withdrawal.status_changed", "w_ctrl_underscore")

      assert json_response(conn, 200) == %{"status" => "ok"}
      assert %{status: :completed} = Core.Repo.reload!(payout)
      assert %{status: :paid} = Core.Repo.reload!(reward)
    end

    test ~s(routes "failed" to Fund.Public, :failed payout, rewards stay :pending_payout),
         %{conn: conn, fund: fund, user: user} do
      {payout, reward} = insert_pending_payout(user, fund, 1000, "w_ctrl_failed")

      expect(ProviderMock, :get_withdrawal, fn "w_ctrl_failed" ->
        {:ok, %{uid: "w_ctrl_failed", status: "failed", amount: 1000}}
      end)

      conn = post_webhook(conn, "withdrawal.status.changed", "w_ctrl_failed")

      assert json_response(conn, 200) == %{"status" => "ok"}
      assert %{status: :failed, failure_reason: reason} = Core.Repo.reload!(payout)
      assert reason =~ "failed"
      assert %{status: :pending_payout} = Core.Repo.reload!(reward)
    end

    test "returns 200 and leaves state untouched when get_withdrawal fails",
         %{conn: conn, fund: fund, user: user} do
      {payout, reward} = insert_pending_payout(user, fund, 1000, "w_ctrl_unreachable")

      expect(ProviderMock, :get_withdrawal, fn "w_ctrl_unreachable" ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
      end)

      conn = post_webhook(conn, "withdrawal.status.changed", "w_ctrl_unreachable")

      # OPP retries failed webhooks; we acknowledge with 200 so the next
      # delivery can be processed when the provider is reachable again.
      assert json_response(conn, 200) == %{"status" => "ok"}
      assert %{status: :pending} = Core.Repo.reload!(payout)
      assert %{status: :pending_payout} = Core.Repo.reload!(reward)
    end

    test "unknown event types are acknowledged with 200 and no state change",
         %{conn: conn, fund: fund, user: user} do
      {payout, reward} = insert_pending_payout(user, fund, 1000, "w_ctrl_unknown_event")

      # No ProviderMock expectation: the controller must not call get_withdrawal
      # for unrecognized event types.

      conn = post_webhook(conn, "withdrawal.something_else", "w_ctrl_unknown_event")

      assert json_response(conn, 200) == %{"status" => "ok"}
      assert %{status: :pending} = Core.Repo.reload!(payout)
      assert %{status: :pending_payout} = Core.Repo.reload!(reward)
    end
  end
end
