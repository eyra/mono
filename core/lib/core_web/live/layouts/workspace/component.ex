defmodule CoreWeb.Layouts.Workspace.Component do
  @moduledoc """
  Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb.UI.Component

  import CoreWeb.UI.OldSkool

  alias CoreWeb.UI.Navigation.{DesktopMenu, TabletMenu, MobileNavbar, MobileMenu}
  alias EyraUI.Hero.HeroSmall

  prop(title, :string)
  prop(menus, :map)

  slot(default, required: true)

  defmacro __using__(active_item) do
    quote do
      alias CoreWeb.Layouts.Workspace.Component, as: Workspace

      data(menus, :map)

      def builder, do: Application.fetch_env!(:core, :workspace_menu_builder)

      def build_menu(socket, type, user, id \\ nil) do
        builder().build_menu(type, socket, user, unquote(active_item), id)
      end

      def build_menus(socket, user, id \\ nil) do
        menus = %{
          mobile_menu: build_menu(socket, :mobile_menu, user, id),
          desktop_menu: build_menu(socket, :desktop_menu, user, id),
          mobile_navbar: build_menu(socket, :mobile_navbar, user, id)
        }

        socket |> assign(menus: menus)
      end

      def update_menus(%{assigns: %{tool_id: tool_id, current_user: current_user}} = socket) do
        socket
        |> build_menus(current_user, tool_id)
      end

      def update_menus(%{assigns: %{current_user: current_user}} = socket) do
        socket
        |> build_menus(current_user)
      end

      def update_menus(%{assigns: %{current_user: current_user}} = socket, id) do
        socket
        |> build_menus(current_user, id)
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-viewport" x-data="{mobile_menu: false}">
      <div class="fixed z-40 right-0 top-0 w-mobile-menu-width h-viewport" x-show="mobile_menu" @click.away="mobile_menu = !mobile_menu, $parent.overlay = false">
        <MobileMenu items={{ @menus.mobile_menu }} path_provider={{ CoreWeb.Router.Helpers }} />
      </div>
      <TabletMenu items={{ @menus.desktop_menu }} path_provider={{ CoreWeb.Router.Helpers }} />
      <DesktopMenu items={{ @menus.desktop_menu }} path_provider={{ CoreWeb.Router.Helpers }} />
      <div class="w-full h-full md:pl-tablet-menu-width lg:pl-desktop-menu-width z-2">
        <div class="pt-0 md:pt-10 h-full">
          <div class="flex flex-col bg-white h-full ">
            <div class="flex-wrap">
              <MobileNavbar items={{ @menus.mobile_navbar }} path_provider={{ CoreWeb.Router.Helpers }} />
            </div>
            <div class="flex-1 bg-white md:border-t md:border-l md:border-b border-grey4">
              <div class="flex flex-col h-full">
                <div class="flex-1">
                  <div class="flex flex-col h-full">
                    <div :if={{ @title }} class="flex-none">
                      <HeroSmall title={{ @title }} />
                    </div>
                    <div class="flex-1">
                      <slot />
                      <MarginY id={{:page_footer_top}} />
                    </div>
                  </div>
                </div>
                <div class="flex-none">
                  {{ footer CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-left.svg"), CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-right.svg") }}
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
