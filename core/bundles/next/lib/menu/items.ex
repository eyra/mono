defmodule Next.Menu.Items do
  use CoreWeb, :verified_routes
  @behaviour CoreWeb.Menu.ItemsProvider

  import CoreWeb.Gettext

  @impl true
  def values() do
    %{
      next: %{action: %{type: :http_get, to: ~p"/"}, title: "Next"},
      desktop: %{
        action: %{type: :redirect, to: ~p"/desktop"},
        title: dgettext("eyra-ui", "menu.item.desktop")
      },
      workspace: %{
        action: %{type: :redirect, to: ~p"/desktop"},
        title: dgettext("eyra-ui", "menu.item.workspace")
      },
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
      todo: %{
        action: %{type: :redirect, to: ~p"/todo"},
        title: dgettext("eyra-ui", "menu.item.todo")
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
        action: %{type: :redirect, to: ~p"/user/signin"},
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
