defmodule Next.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  @impl true
  def values() do
    %{
      next: %{action: %{type: :http_get, to: ~p"/console"}, title: "Next"},
      admin: %{
        action: %{type: :redirect, to: ~p"/admin/config"},
        title: dgettext("eyra-ui", "menu.item.admin")
      },
      helpdesk: %{
        action: %{type: :redirect, to: ~p"/support/helpdesk"},
        title: dgettext("eyra-ui", "menu.item.helpdesk")
      },
      support: %{
        action: %{type: :redirect, to: ~p"/support/ticket"},
        title: dgettext("eyra-ui", "menu.item.support")
      },
      console: %{
        action: %{type: :redirect, to: ~p"/console"},
        title: dgettext("eyra-ui", "menu.item.console")
      },
      todo: %{
        action: %{type: :redirect, to: ~p"/todo"},
        title: dgettext("eyra-ui", "menu.item.todo")
      },
      settings: %{
        action: %{type: :redirect, to: ~p"/user/settings"},
        title: dgettext("eyra-ui", "menu.item.settings")
      },
      profile: %{
        action: %{type: :redirect, to: ~p"/user/profile"},
        title: dgettext("eyra-ui", "menu.item.profile")
      },
      signout: %{
        action: %{type: :http_delete, to: ~p"/user/signout"},
        title: dgettext("eyra-ui", "menu.item.signout")
      },
      signin: %{
        action: %{type: :http_get, to: ~p"/user/signin"},
        title: dgettext("eyra-ui", "menu.item.signin")
      },
      menu: %{
        action: %{type: :click, code: "mobile_menu = !mobile_menu"},
        title: dgettext("eyra-ui", "menu.item.menu")
      },
      payments: %{
        action: %{type: :redirect, to: "/payment"},
        title: dgettext("eyra-ui", "menu.item.payments")
      },
      projects: %{
        action: %{type: :redirect, to: "/project"},
        title: dgettext("eyra-ui", "menu.item.projects")
      }
    }
  end
end
