defmodule CoreWeb.Layouts.Website.Component do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use Surface.Component

  import EyraUI.Components.OldSkool

  alias EyraUI.Navigation.{DesktopNavbar, MobileNavbar, MobileMenu}
  alias EyraUI.Hero.HeroLarge

  prop(title, :string, required: true)
  prop(subtitle, :string, required: true)
  prop(user, :string, required: true)
  prop(user_agent, :string, required: true)
  prop(active_item, :any, required: true)
  prop(id, :string)

  slot(default, required: true)

  defp builder, do: Application.fetch_env!(:core, :website_menu_builder)

  defp build_menu(type, socket) do
    builder().build_menu(
      type,
      socket,
      socket,
      socket.assigns.__assigns__.active_item,
      socket.assigns.__assigns__.id
    )
  end

  def render(assigns) do
    ~H"""
      <div x-data="{native_menu: false, mobile_menu: false}" @toggle-native-menu.window="native_menu = !native_menu">
        <div class="fixed z-30 right-0 top-0 w-mobile-menu-width h-screen" x-show="mobile_menu" @click.away="mobile_menu = !mobile_menu, $parent.overlay = false">
          <MobileMenu items={{ build_menu(:mobile_menu, @socket) }} path_provider={{ CoreWeb.Router.Helpers }} />
        </div>
        <div class="flex flex-col w-full h-screen">
          <div class="flex-wrap">
            <MobileNavbar items={{ build_menu(:mobile_navbar, @socket) }} path_provider={{ CoreWeb.Router.Helpers }} />
            <DesktopNavbar items={{ build_menu(:desktop_navbar, @socket) }} path_provider={{ CoreWeb.Router.Helpers }} />
          </div>
          <div class="bg-white flex-grow">
            <HeroLarge title={{ @title }} subtitle={{ @subtitle }}/>
            <slot />
          </div>
          <div class="pb-0 md:pb-10 bg-grey5">
            <div class="bg-white">
              {{ footer CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-left.svg"), CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-right.svg") }}
            </div>
          </div>
        </div>
      </div>
    """
  end
end
