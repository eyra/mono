defmodule Systems.Pool.ContentPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Content
  alias Systems.Pool

  def view_model(%Pool.Model{id: pool_id} = pool, %{current_user: user} = assigns) do
    is_admin? = Admin.Public.admin?(user)
    locale = Map.get(assigns, :locale, :en)

    live_context =
      LiveContext.new(%{
        pool_id: pool_id,
        current_user: user,
        locale: locale,
        is_admin?: is_admin?
      })

    %{
      title: dgettext("eyra-pool", "content.title"),
      tabs: build_tabs(pool, live_context),
      breadcrumbs: build_breadcrumbs(pool, locale, is_admin?),
      show_errors: false,
      active_menu_item: :admin
    }
  end

  defp build_tabs(%Pool.Model{id: pool_id}, live_context) do
    [
      participants_tab(pool_id, live_context),
      settings_tab(pool_id, live_context)
    ]
  end

  defp participants_tab(pool_id, live_context) do
    element =
      CoreWeb.Live.Element.prepare_live_view(
        "pool_participants_view_#{pool_id}",
        Pool.ParticipantsView,
        live_context: live_context
      )

    %{
      id: :participants,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-pool", "participants.title"),
      type: :fullpage,
      element: element
    }
  end

  defp settings_tab(pool_id, live_context) do
    element =
      CoreWeb.Live.Element.prepare_live_view(
        "pool_settings_view_#{pool_id}",
        Pool.SettingsView,
        live_context: live_context
      )

    %{
      id: :settings,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-pool", "settings.title"),
      type: :fullpage,
      element: element
    }
  end

  defp build_breadcrumbs(%Pool.Model{name: pool_name, org: org}, locale, true = _is_admin?) do
    [
      %{label: dgettext("eyra-admin", "config.title"), path: "/admin/config"},
      %{label: org_label(org, locale), path: "/org/node/#{org.id}"},
      %{label: pool_name, path: nil}
    ]
  end

  defp build_breadcrumbs(%Pool.Model{name: pool_name, org: org}, locale, false = _is_admin?) do
    [
      %{label: org_label(org, locale), path: "/org/node/#{org.id}"},
      %{label: pool_name, path: nil}
    ]
  end

  defp org_label(%{full_name_bundle: full_name_bundle}, locale) do
    Content.TextBundleModel.text(full_name_bundle, locale)
  end
end
