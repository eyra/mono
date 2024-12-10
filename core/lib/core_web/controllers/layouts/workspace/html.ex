defmodule CoreWeb.Layouts.Workspace.Html do
  @moduledoc """
  Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer

  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Hero

  attr(:title, :string, default: nil)
  attr(:menus, :map)
  attr(:footer, :boolean, default: true)
  slot(:top_bar)
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
                          <Hero.illustration2 title={@title} />
                        </div>
                      <% end %>
                      <%= if @top_bar != [] do %>
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
