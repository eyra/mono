defmodule CoreWeb.Layouts.Workspace do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use Surface.Component

  import EyraUI.Components.OldSkool

  alias CoreWeb.Layouts.Workspace.{DesktopMenuBuilder, MobileMenuBuilder, MobileNavbarBuilder}

  alias EyraUI.Navigation.{DesktopMenu, MobileNavbar, MobileMenu}
  alias EyraUI.Hero.HeroSmall

  prop(title, :string)
  prop(user_agent, :string, required: true)
  prop(active_item, :any, required: true)
  prop(id, :string)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="w-full h-screen" x-data="{mobile_menu: false}">
      <div class="fixed z-30 right-0 top-0 w-mobile-menu-width h-screen" x-show="mobile_menu" @click.away="mobile_menu = !mobile_menu, $parent.overlay = false">
        <MobileMenu items={{ MobileMenuBuilder.build_menu(@socket, @socket, @active_item, @id) }} path_provider={{ CoreWeb.Router.Helpers }} />
      </div>
      <DesktopMenu items={{ DesktopMenuBuilder.build_menu(@socket, @socket, @active_item, @id) }} path_provider={{ CoreWeb.Router.Helpers }} />
      <div class="w-full h-full md:pl-desktop-menu-width z-2">
        <div class="pt-0 md:pt-10 h-full">
          <div class="flex flex-col bg-white min-h-full">
            <MobileNavbar items={{ MobileNavbarBuilder.build_menu(@socket, @socket, @active_item, @id) }} path_provider={{ CoreWeb.Router.Helpers }} />
            <div :if={{ @title }}>
              <HeroSmall title={{ @title }} />
            </div>
            <div class="flex-1">
              <div class="flex flex-col h-full">
                <div>
                  <slot />
                </div>
                <div class="flex-1">
                </div>
              </div>
            </div>
            <div class="pb-0 md:pb-10 bg-grey5">
                <div class="bg-white">
                  {{ footer CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-left.svg"), CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-right.svg") }}
                </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
