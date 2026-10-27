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

  test "system admins see every panel" do
    assert Admin.Panel.shown_to?(AdminOnlyPanel, :admin)
    assert Admin.Panel.shown_to?(OrgAdminPanel, :admin)
  end

  test "org admins only see org admin panels" do
    refute Admin.Panel.shown_to?(AdminOnlyPanel, :org_admin)
    assert Admin.Panel.shown_to?(OrgAdminPanel, :org_admin)
  end

  test "the live context is the page's context unless the panel extends it" do
    context = LiveContext.new(%{locale: :en})

    assert AdminOnlyPanel.live_context(context) == context
  end

  test "the page shows the panels in system order, per audience" do
    assert Admin.ConfigPageBuilder.tab_ids() == %{
             admin: [:system, :account, :org, :actions, :client_activity],
             org_admin: [:org]
           }
  end
end
