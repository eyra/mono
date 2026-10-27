defmodule Systems.Desktop.PageTest do
  @moduledoc """
  The banner tests are regression coverage for FX#9905887344 — when a user's
  AddDomainMembers NextAction is cleared in another process (e.g. their :owner
  role is revoked), the next-best-action banner on /desktop must disappear
  without a manual refresh.

  The section tests contribute `Systems.Desktop.TestSection` through
  `config :core, Systems.Desktop, sections: [...]`.
  """
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  import Frameworks.Signal.TestHelper

  alias Core.Factories
  alias Frameworks.Signal
  alias Systems.Desktop
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

  describe "sections" do
    setup ctx do
      user = Factories.insert!(:creator)
      {:ok, ctx} = login(user, ctx)
      {:ok, Keyword.put(ctx, :user, user)}
    end

    test "without contributed sections, Desktop shows only Recent items", %{conn: conn} do
      assert Core.SaaS.desktop_sections() == []

      {:ok, view, html} = live(conn, ~p"/desktop")

      assert html =~ "Recent items"
      refute has_element?(view, "[id^=desktop_section_]")
    end

    test "a contributed section shows after Recent items", %{conn: conn} do
      contribute_test_section(message: "Hello from the test section")

      {:ok, view, html} = live(conn, ~p"/desktop")

      assert has_element?(view, "#desktop_section_test", "Test section")
      assert has_element?(view, "#desktop_section_test", "Hello from the test section")

      {recent_items, _} = :binary.match(html, "Recent items")
      {section, _} = :binary.match(html, "desktop_section_test")
      assert recent_items < section
    end

    test "a section without a view model is hidden", %{conn: conn} do
      contribute_test_section([])

      {:ok, view, _html} = live(conn, ~p"/desktop")

      refute has_element?(view, "#desktop_section_test")
    end

    test "a contributed section refreshes live through its own Switch", %{conn: conn, user: user} do
      contribute_test_section(message: "Before")
      override_signal_handlers(Core.SaaS.signal_handlers() ++ [Desktop.TestSection.Switch])
      on_exit(&restore_signal_handlers/0)

      {:ok, view, _html} = live(conn, ~p"/desktop")
      assert has_element?(view, "#desktop_section_test", "Before")

      put_env(Desktop.TestSection, message: "After")
      Signal.Public.dispatch!({:desktop_test_section, :updated}, %{user: user, from_pid: self()})

      assert has_element?(view, "#desktop_section_test", "After")
    end
  end

  defp contribute_test_section(config) do
    put_env(Systems.Desktop, sections: [Desktop.TestSection])
    put_env(Desktop.TestSection, config)
  end

  defp put_env(key, value) do
    original = Application.get_env(:core, key)
    Application.put_env(:core, key, value)

    on_exit(fn ->
      if original,
        do: Application.put_env(:core, key, original),
        else: Application.delete_env(:core, key)
    end)
  end
end
