defmodule Systems.Admin.ConfigPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Org

  @doc "Tab ids in display order, for system admins and for org admins."
  def tab_ids do
    %{
      admin: Enum.map(panels(:admin), & &1.id()),
      org_admin: Enum.map(panels(:org_admin), & &1.id())
    }
  end

  @doc "The panels `viewer` sees, in `Core.SaaS.admin_panels/0` order."
  def panels(viewer),
    do: Enum.filter(Core.SaaS.admin_panels(), &Admin.Panel.shown_to?(&1, viewer))

  def view_model(%{id: :singleton}, %{current_user: user} = assigns) do
    locale = Map.get(assigns, :locale, :en)
    is_admin? = Admin.Public.admin?(user)
    governable_orgs = Org.Public.list_orgs(user, Org.NodeModel.preload_graph(:full))

    # Sync NextActions as fallback when opening admin page
    Org.Public.sync_all_domain_match_next_actions(user)

    live_context =
      LiveContext.new(%{
        current_user: user,
        locale: locale,
        is_admin?: is_admin?,
        governable_orgs: governable_orgs
      })

    %{
      tabbar_id: "admin_config",
      title: get_title(is_admin?, governable_orgs),
      active_menu_item: :admin,
      show_errors: false,
      tabs: create_tabs(viewer(is_admin?, governable_orgs), live_context)
    }
  end

  # Page title is always "Admin" (matches menu item)
  defp get_title(_, _), do: dgettext("eyra-admin", "config.title")

  defp viewer(true, _governable_orgs), do: :admin
  defp viewer(false, [_ | _]), do: :org_admin
  defp viewer(_is_admin?, _governable_orgs), do: nil

  defp create_tabs(nil, _live_context), do: []

  defp create_tabs(viewer, live_context) do
    Enum.map(panels(viewer), &create_tab(&1, live_context))
  end

  defp create_tab(panel, live_context) do
    id = panel.id()

    element =
      CoreWeb.Live.Element.prepare_live_view(
        "admin_#{id}_view",
        panel.live_view(),
        live_context: panel.live_context(live_context)
      )

    %{
      id: id,
      ready: false,
      show_errors: false,
      title: panel.title(),
      type: :fullpage,
      element: element
    }
  end
end
