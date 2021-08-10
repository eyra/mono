defmodule CoreWeb.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  @impl true
  def values(),
    do: %{
      eyra: %{target: CoreWeb.Index, size: :large, domain: "eyra-ui"},
      dashboard: %{target: CoreWeb.Dashboard, domain: "eyra-ui"},
      marketplace: %{target: CoreWeb.Marketplace, domain: "eyra-ui"},
      todo: %{target: CoreWeb.Todo, domain: "eyra-ui"},
      payments: %{target: CoreWeb.Dashboard, domain: "eyra-ui"},
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
