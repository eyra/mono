defmodule Link.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  @impl true
  def values() do
    %{
      link: %{action: %{type: :redirect, to: ~p"/"}, title: "Panl"},
      admin: %{
        action: %{type: :redirect, to: ~p"/admin/config"},
        title: dgettext("eyra-ui", "menu.item.admin")
      },
      support: %{
        action: %{type: :redirect, to: ~p"/support/tickets"},
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
      helpdesk: %{
        action: %{type: :redirect, to: ~p"/support/helpdesk"},
        title: dgettext("eyra-ui", "menu.item.helpdesk")
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
      debug: %{
        action: %{type: :redirect, to: ~p"/debug"},
        title: dgettext("eyra-ui", "menu.item.debug")
      },
      funding: %{
        action: %{type: :redirect, to: ~p"/funding"},
        title: dgettext("eyra-ui", "menu.item.funding")
      },
      marketplace: %{
        action: %{type: :redirect, to: ~p"/marketplace"},
        title: dgettext("eyra-ui", "menu.item.marketplace")
      },
      pools: %{
        action: %{type: :redirect, to: ~p"/pool"},
        title: dgettext("link-ui", "menu.item.pools")
      },
      recruitment: %{
        action: %{type: :redirect, to: ~p"/recruitment"},
        title: dgettext("link-ui", "menu.item.recruitment")
      },
      menu: %{
        action: %{type: :click, code: "mobile_menu = !mobile_menu"},
        title: dgettext("eyra-ui", "menu.item.menu")
      }
    }
  end
end
