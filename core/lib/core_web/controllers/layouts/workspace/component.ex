defmodule CoreWeb.Layouts.Workspace.Component do
  @moduledoc """
  Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer

  alias CoreWeb.UI.Navigation
  alias Frameworks.Pixel.Hero

  defmacro __using__(active_item) do
    quote do
      import CoreWeb.Layouts.Workspace.Component

      @menus [
        :mobile_menu,
        :mobile_navbar,
        :desktop_menu,
        :tablet_menu
      ]

      def builder, do: Application.fetch_env!(:core, :workspace_menu_builder)

      def build_menu(assigns, type) do
        builder().build_menu(assigns, type, unquote(active_item))
      end

      def build_menus(%{assigns: assigns} = socket) do
        menus = build_menus(assigns)
        socket |> assign(menus: menus)
      end

      def build_menus(assigns) do
        Enum.reduce(@menus, %{}, fn menu_id, acc ->
          Map.put(acc, menu_id, build_menu(assigns, menu_id))
        end)
      end

      def update_menus(socket) do
        socket
        |> build_menus()
      end

      def handle_uri(socket) do
        update_menus(socket)
      end
    end
  end

  attr(:title, :string, default: nil)
  attr(:menus, :map)
  attr(:footer, :boolean, default: true)
  slot(:top_bar, default: nil)
  slot(:inner_block, required: true)

  def workspace(assigns) do
    ~H"""
    <div class="w-full h-viewport" x-data="{mobile_menu: false}">
      <div
        class="fixed right-0 top-0 w-mobile-menu-width h-viewport"
        x-cloak
        x-show="mobile_menu"
        @click.away="mobile_menu = !mobile_menu, $parent.overlay = false"
      >
        <Navigation.mobile_menu {@menus.mobile_menu} />
      </div>
      <div class="fixed full w-full h-full flex flex-row" >
        <div class="h-full">
          <Navigation.tablet_menu {@menus.tablet_menu} />
          <Navigation.desktop_menu {@menus.desktop_menu} />
        </div>
        <div class="w-full h-full">
          <div class="h-full w-full overflow-hidden">
            <div id="main-content" class="flex flex-col w-full h-full scrollbar-hidden overflow-scroll">
              <div class="flex-wrap">
                <Navigation.mobile_navbar {@menus.mobile_navbar} />
              </div>
              <div class="flex-1 pt-0 md:pt-10">
                <div class="flex flex-col h-full md:border-t md:border-l md:border-b border-grey4 bg-white">
                  <div class="flex-1">
                    <div class="flex flex-col h-full w-full">
                      <%= if @title do %>
                        <div class="flex-none">
                          <Hero.small title={@title} />
                        </div>
                      <% end %>
                      <%= if @top_bar do %>
                        <div class="flex-none">
                          <%= render_slot(@top_bar) %>
                        </div>
                      <% end %>
                      <div id="layout-inner-block" class="flex-1">
                        <%= render_slot(@inner_block) %>
                        <Margin.y id={:page_footer_top} />
                      </div>
                    </div>
                  </div>
                  <%= if @footer do %>
                    <div class="flex-none">
                      <.content_footer />
                    </div>
                  <% end %>
                </div>
              </div>
              <div class="bg-grey5">
                <.platform_footer />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
