defmodule Systems.Admin.PanelTest do
  use ExUnit.Case, async: true

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin

  defmodule AdminOnlyPanel do
    use Systems.Admin.Panel

    def id, do: :admin_only
    def title, do: "Admin only"
    def audience, do: :admin
    def live_view, do: Systems.Admin.ActionsView
  end

  defmodule OrgAdminPanel do
    use Systems.Admin.Panel

    def id, do: :org_admin
    def title, do: "Org admin"
    def audience, do: :org_admin
    def live_view, do: Systems.Admin.OrgView
  end

  defmodule DisabledPanel do
    use Systems.Admin.Panel

    def id, do: :disabled
    def title, do: "Disabled"
    def audience, do: :org_admin
    def enabled?, do: false
    def live_view, do: Systems.Admin.OrgView
  end

  test "system admins see every enabled panel" do
    assert Admin.Panel.shown_to?(AdminOnlyPanel, :admin)
    assert Admin.Panel.shown_to?(OrgAdminPanel, :admin)
  end

  test "org admins only see enabled org admin panels" do
    refute Admin.Panel.shown_to?(AdminOnlyPanel, :org_admin)
    assert Admin.Panel.shown_to?(OrgAdminPanel, :org_admin)
  end

  test "panels are enabled unless they say otherwise" do
    assert AdminOnlyPanel.enabled?()
  end

  test "nobody sees a disabled panel, though it keeps its audience" do
    refute Admin.Panel.shown_to?(DisabledPanel, :admin)
    refute Admin.Panel.shown_to?(DisabledPanel, :org_admin)
    assert Admin.Panel.in_audience?(DisabledPanel, :org_admin)
  end

  test "the live context is the page's context unless the panel extends it" do
    context = LiveContext.new(%{locale: :en})

    assert AdminOnlyPanel.live_context(context) == context
  end

  test "the page shows the panels in system order, per audience" do
    %{admin: admin, org_admin: org_admin} = Admin.ConfigPageBuilder.tab_ids()

    # The SaaS's own systems add their panels after these.
    assert Enum.take(admin, 5) == [:system, :account, :org, :actions, :client_activity]
    assert org_admin == [:org]
  end
end
