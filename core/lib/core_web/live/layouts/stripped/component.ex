defmodule CoreWeb.Layouts.Stripped.Component do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb.UI.Component

  import CoreWeb.UI.OldSkool

  alias CoreWeb.UI.Navigation.{DesktopNavbar, MobileNavbar}

  prop(user, :string, required: true)
  prop(menus, :map, required: true)

  slot(default, required: true)

  defmacro __using__(active_item) do
    quote do
      alias CoreWeb.Layouts.Website.Component, as: Website

      data(menus, :map)

      def builder, do: Application.fetch_env!(:core, :stripped_menu_builder)

      def build_menu(socket, type, user) do
        builder().build_menu(type, socket, user, unquote(active_item))
      end

      def build_menus(socket, user) do
        menus = %{
          mobile_navbar: build_menu(socket, :mobile_navbar, user),
          desktop_navbar: build_menu(socket, :desktop_navbar, user)
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
      <div class="flex flex-row">
        <div class="w-0 md:w-sidepadding flex-shrink-0">
        </div>
        <div class="flex-1">
          <div class="flex flex-col w-full h-viewport">
            <div class="flex-wrap">
              <MobileNavbar items={@menus.mobile_navbar} path_provider={CoreWeb.Router.Helpers} />
              <DesktopNavbar items={@menus.desktop_navbar} path_provider={CoreWeb.Router.Helpers} />
            </div>
            <div class="flex-1">
              <div class="flex flex-col h-full border-t border-l border-b border-grey4">
                <div class="flex-1 bg-white">
                  <div class="flex flex-row">
                    <div class="flex-1">
                      <#slot />
                      <MarginY id={:page_footer_top} />
                    </div>
                    <div class="w-0 md:w-sidepadding flex-shrink-0">
                    </div>
                  </div>
                </div>
                <div class="bg-white">
                  {footer CoreWeb.Endpoint.static_path("/images/footer-left.svg"), CoreWeb.Endpoint.static_path("/images/footer-right.svg")}
                </div>
              </div>
            </div>
            <div class="pb-0 md:pb-10 bg-grey5">
            </div>
          </div>
        </div>
      </div>
    """
  end
end
