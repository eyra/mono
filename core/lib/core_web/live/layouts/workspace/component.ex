defmodule CoreWeb.Layouts.Workspace.Component do
  @moduledoc """
  Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb.UI.Component

  import CoreWeb.UI.OldSkool

  alias CoreWeb.UI.Navigation.{DesktopMenu, TabletMenu, MobileNavbar, MobileMenu}
  alias Frameworks.Pixel.Hero.HeroSmall

  prop(title, :string)
  prop(menus, :map)

  slot(default, required: true)

  defoverridable __using__: 1

  defmacro __using__(active_item) do
    super_use = super([])

    quote do
      unquote(super_use)

      alias CoreWeb.Layouts.Workspace.Component, as: Workspace

      data(menus, :map)

      def builder, do: Application.fetch_env!(:core, :workspace_menu_builder)

      def build_menu(socket, type, user) do
        builder().build_menu(type, socket, user, unquote(active_item))
      end

      def build_menus(socket, user) do
        menus = %{
          mobile_menu: build_menu(socket, :mobile_menu, user),
          tablet_menu: build_menu(socket, :tablet_menu, user),
          desktop_menu: build_menu(socket, :desktop_menu, user),
          mobile_navbar: build_menu(socket, :mobile_navbar, user)
        }

        socket |> assign(menus: menus)
      end

      def update_menus(%{assigns: %{current_user: current_user}} = socket) do
        socket
        |> build_menus(current_user)
      end

      def handle_uri(socket) do
        update_menus(socket)
      end
    end
  end

  def render(assigns) do
    ~F"""
    <div class="w-full h-viewport" x-data="{mobile_menu: false}">
      <div
        class="fixed z-40 right-0 top-0 w-mobile-menu-width h-viewport"
        x-show="mobile_menu"
        @click.away="mobile_menu = !mobile_menu, $parent.overlay = false"
      >
        <MobileMenu items={@menus.mobile_menu} path_provider={CoreWeb.Endpoint} />
      </div>
      <TabletMenu items={@menus.tablet_menu} path_provider={CoreWeb.Endpoint} />
      <DesktopMenu items={@menus.desktop_menu} path_provider={CoreWeb.Endpoint} />
      <div class="w-full h-full md:pl-tablet-menu-width lg:pl-desktop-menu-width z-2">
        <div class="pt-0 md:pt-10 h-full">
          <div class="flex flex-col bg-white h-full">
            <div class="flex-wrap">
              <MobileNavbar items={@menus.mobile_navbar} path_provider={CoreWeb.Endpoint} />
            </div>
            <div class="flex-1 bg-white md:border-t md:border-l md:border-b border-grey4">
              <div class="flex flex-col h-full">
                <div class="flex-1">
                  <div class="flex flex-col h-full">
                    <div :if={@title} class="flex-none">
                      <HeroSmall title={@title} />
                    </div>
                    <div class="flex-1">
                      <#slot />
                      <MarginY id={:page_footer_top} />
                    </div>
                  </div>
                </div>
                <div class="flex-none">
                  {footer(
                    assigns,
                    CoreWeb.Endpoint.static_path("/images/footer-left.svg"),
                    CoreWeb.Endpoint.static_path("/images/footer-right.svg")
                  )}
                </div>
              </div>
            </div>
            <div class="pb-0 md:pb-10 bg-grey5">
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
