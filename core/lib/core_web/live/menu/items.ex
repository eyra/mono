defmodule CoreWeb.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  @impl true
  def values(),
    do: %{
      admin: %{target: Systems.Admin.ConfigPage, domain: "eyra-ui"},
      support: %{target: Systems.Support.OverviewPage, domain: "eyra-ui"},
      eyra: %{target: Systems.Home.LandingPage, size: :large, title: "Eyra", domain: "eyra-ui"},
      console: %{target: CoreWeb.Console, domain: "eyra-ui"},
      todo: %{target: Systems.NextAction.OverviewPage, domain: "eyra-ui"},
      payments: %{target: CoreWeb.Console, domain: "eyra-ui"},
      helpdesk: %{target: Systems.Support.HelpdeskPage, domain: "eyra-ui"},
      settings: %{target: CoreWeb.User.Settings, domain: "eyra-ui"},
      profile: %{target: CoreWeb.User.Profile, domain: "eyra-ui"},
      signout: %{target: :delete, domain: "eyra-ui"},
      signin: %{target: :new, domain: "eyra-ui"},
      menu: %{target: "mobile_menu = !mobile_menu", domain: "eyra-ui"}
    }

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote do
        for {item_id, %{domain: domain}} <- CoreWeb.Menu.Items.values() do
          quote do
            dgettext(unquote(domain), unquote("menu.item.#{item_id}"))
          end
        end
      end
    end
  end
end
