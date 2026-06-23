defmodule Systems.Account.PayoutsReactiveTest do
  @moduledoc """
  Proves the webhook → signal → Observatory → re-render path: when OPP approves
  the bank account and `{:payment_kyc, :updated}` is dispatched, the mounted
  PayoutsView re-fetches its status and the badge flips without a reload.
  """
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Mox

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Payment.ProviderMock

  setup :set_mox_global

  setup do
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_rx"})
    {:ok, bank} = Agent.start_link(fn -> "pending" end)

    stub(ProviderMock, :get_merchant, fn "m_rx" ->
      {:ok,
       %{
         uid: "m_rx",
         status: "live",
         kyc_level: 100,
         compliance_status: "verified",
         overview_url: nil
       }}
    end)

    stub(ProviderMock, :list_bank_accounts, fn "m_rx" ->
      {:ok, [%{uid: "ba", status: Agent.get(bank, & &1), verification_url: "https://opp.test/ba/verify"}]}
    end)

    %{user: user, bank: bank}
  end

  test "bank badge flips pending -> verified when the KYC webhook fires", %{
    conn: conn,
    user: user,
    bank: bank
  } do
    conn = Map.put(conn, :request_path, "/user/profile/payouts")
    session = %{"live_context" => LiveContext.new(%{user_id: user.id})}

    {:ok, view, html} = live_isolated(conn, Account.PayoutsView, session: session)
    assert html =~ "Being verified"

    # OPP approves the bank account; the webhook arrives as {:payment_kyc, :updated},
    # which Account.Switch turns into the Observatory broadcast below.
    Agent.update(bank, fn _ -> "approved" end)
    Account.Switch.intercept({:payment_kyc, :updated}, %{user_id: user.id})

    assert eventually_render(view, "Verified") =~ "Verified"
  end

  defp eventually_render(view, _expected, 0), do: render(view)

  defp eventually_render(view, expected, retries) do
    html = render(view)

    if html =~ expected do
      html
    else
      Process.sleep(25)
      eventually_render(view, expected, retries - 1)
    end
  end

  defp eventually_render(view, expected), do: eventually_render(view, expected, 20)
end
