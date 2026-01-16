defmodule Systems.Org.ContentPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Content
  alias Systems.Org

  def view_model(
        %{id: node_id, full_name_bundle: full_name_bundle} = node,
        %{current_user: user} = assigns
      ) do
    is_admin? = Admin.Public.admin?(user)
    locale = Map.get(assigns, :locale, :en)
    org_name = Content.TextBundleModel.text(full_name_bundle, locale)
    governable_orgs = Org.Public.list_orgs(user)

    live_context =
      LiveContext.new(%{
        node_id: node_id,
        current_user: user,
        locale: locale,
        is_admin?: is_admin?
      })

    assigns_with_context = Map.put(assigns, :live_context, live_context)

    %{
      title: dgettext("eyra-admin", "config.title"),
      tabs: create_tabs(node, assigns_with_context),
      breadcrumbs: create_breadcrumbs(org_name, is_admin?, governable_orgs),
      show_errors: false,
      active_menu_item: :admin
    }
  end

  # System admin or org admin with multiple orgs: show full breadcrumb path
  defp create_breadcrumbs(org_name, true = _is_admin?, _governable_orgs) do
    [
      %{label: dgettext("eyra-admin", "config.title"), path: "/admin/config"},
      %{label: org_name, path: nil}
    ]
  end

  defp create_breadcrumbs(org_name, false, governable_orgs) when length(governable_orgs) > 1 do
    [
      %{label: dgettext("eyra-admin", "config.title"), path: "/admin/config"},
      %{label: org_name, path: nil}
    ]
  end

  # Org admin with single org: show only org name (no back link needed)
  defp create_breadcrumbs(org_name, false, _governable_orgs) do
    [
      %{label: org_name, path: nil}
    ]
  end

  defp create_tabs(node, assigns) do
    [:users, :node]
    |> Enum.map(&create_tab(&1, node, assigns))
  end

  defp create_tab(:node, %{id: node_id}, %{live_context: context}) do
    element =
      LiveNest.Element.prepare_live_view(
        "org_node_view_#{node_id}",
        Org.NodeView,
        live_context: context
      )

    %{
      id: :node,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-org", "node.title"),
      type: :fullpage,
      element: element
    }
  end

  defp create_tab(:users, %{id: node_id}, %{live_context: context}) do
    element =
      LiveNest.Element.prepare_live_view(
        "org_user_view_#{node_id}",
        Org.UserView,
        live_context: context
      )

    %{
      id: :users,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-org", "user.title"),
      type: :fullpage,
      element: element
    }
  end
end
