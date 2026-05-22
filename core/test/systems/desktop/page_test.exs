defmodule Systems.Desktop.PageTest do
  @moduledoc """
  Regression coverage for FX#9905887344 — when a user's AddDomainMembers
  NextAction is cleared in another process (e.g. their :owner role is
  revoked), the next-best-action banner on /desktop must disappear
  without a manual refresh.
  """
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Org

  describe "next-best-action banner" do
    test "disappears live when the AddDomainMembers NextAction is cleared",
         ctx do
      domain = "desktop-banner-refresh.test"
      org = Factories.insert!(:org_node, %{identifier: ["desktop_banner_org"], domains: [domain]})
      _candidate = Factories.insert!(:member, %{email: "candidate@#{domain}"})
      owner = Factories.insert!(:creator)

      :ok = Org.Public.assign_owner(org, owner)

      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn]

      {:ok, view, html} = live(conn, ~p"/desktop")
      assert html =~ "New members available for"

      # Revoke in this process: clear_next_action dispatches
      # {:next_action, :cleared}, Desktop.Switch then dispatches a
      # {:routed, Desktop.Page} observation, the LiveView mailbox
      # receives it, the view model rebuilds.
      :ok = Org.Public.revoke_owner(org, owner)

      refute render(view) =~ "New members available for"
    end
  end
end
