defmodule CoreWeb.Layouts.Stripped.Component do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer
  alias CoreWeb.UI.Navigation
  alias Frameworks.Pixel.Hero

  defmacro __using__(active_item) do
    quote do
      import CoreWeb.Layouts.Stripped.Component

      @menus [
        :mobile_navbar,
        :desktop_navbar
      ]

      def builder, do: Application.fetch_env!(:core, :stripped_menu_builder)

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
  attr(:menus, :map, required: true)
  slot(:inner_block, required: true)

  def stripped(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="w-0 md:w-sidepadding flex-shrink-0">
      </div>
      <div class="flex-1">
        <div class="flex flex-col w-full h-viewport">
            <div class="flex-wrap md:hidden">
              <Navigation.mobile_navbar {@menus.mobile_navbar} />
            </div>
            <div class="flex-wrap hidden md:flex">
              <Navigation.desktop_navbar {@menus.desktop_navbar} />
            </div>
          <div class="flex-1">
            <div class="flex flex-col h-full border-t border-l border-b border-grey4">
              <%= if @title do %>
                <div class="flex-none">
                  <Hero.small title={@title} />
                </div>
              <% end %>
              <div class="flex-1 bg-white">
                <div class="flex flex-row">
                  <div class="flex-1">
                    <%= render_slot(@inner_block) %>
                    <Margin.y id={:page_footer_top} />
                  </div>
                  <div class="w-0 md:w-sidepadding flex-shrink-0">
                  </div>
                </div>
              </div>
              <div class="bg-white">
                <.content_footer />
              </div>
            </div>
          </div>
          <div class="bg-grey5">
            <.platform_footer />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
