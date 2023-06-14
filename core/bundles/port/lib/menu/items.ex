defmodule Port.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  @impl true
  def values() do
    %{
      eyra: %{action: %{type: :http_get, to: ~p"/"}, title: "Eyra"},
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
        action: %{type: :http_delete, to: ~p"/user/session"},
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
      projects: %{
        action: %{type: :redirect, to: ~p"/project"},
        title: dgettext("eyra-ui", "menu.item.projects")
      }
    }
  end
end
