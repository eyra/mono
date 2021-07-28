defmodule Link.Menu.Items do
  @behaviour CoreWeb.Menu.ItemsProvider

  @impl true
  def values(), do: %{
    eyra: %{target: CoreWeb.Index, size: :large, domain: "eyra-ui"},
    dashboard: %{target: Link.Dashboard, domain: "eyra-ui"},
    marketplace: %{target: Link.Dashboard, domain: "eyra-ui"},
    inbox: %{target: Link.Dashboard, domain: "eyra-ui"},
    payments: %{target: Link.Dashboard, domain: "eyra-ui"},
    settings: %{target: CoreWeb.User.Settings, domain: "eyra-ui"},
    profile: %{target: CoreWeb.User.Profile, domain: "eyra-ui"},
    signout: %{target: :delete, domain: "eyra-ui"},
    signin: %{target: :new, domain: "eyra-ui"},
    menu: %{target: "mobile_menu = !mobile_menu", domain: "eyra-ui"}
  }

end
