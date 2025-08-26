defmodule CoreWeb.Layouts.Website.Html do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer

  alias Frameworks.Pixel.Navigation

  attr(:user, :string, required: true)
  attr(:user_agent, :string, required: true)
  attr(:menus, :map)
  attr(:include_right_sidepadding?, :boolean, default: true)

  slot(:inner_block, required: true)
  slot(:hero, required: true)

  def website(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-1">
        <div
          x-data="{native_menu: false, mobile_menu: false}"
          @toggle-native-menu.window="native_menu = !native_menu"
        >
          <div
            class="fixed z-30 right-0 top-0 w-mobile-menu-width h-viewport"
            x-cloak
            x-show="mobile_menu"
            @click.away="mobile_menu = !mobile_menu, $parent.overlay = false"
          >
            <Navigation.mobile_menu {@menus.mobile_menu} />
          </div>
          <div id="main-content" class="flex flex-col w-full h-viewport">
            <div class="flex-wrap lg:hidden">
              <Navigation.mobile_navbar {@menus.mobile_navbar} />
            </div>
            <div class="flex-wrap hidden lg:flex">
              <Navigation.desktop_navbar {@menus.desktop_navbar} />
            </div>
            <div class="flex-1">
              <div class="flex flex-col h-full border-t border-b border-grey4">
                <div class="bg-white">
                  <%= render_slot(@hero) %>
                </div>
                <div class="flex-1 bg-white">
                  <div class="flex flex-row">
                    <div id="layout-inner-block" class="flex-1">
                      <%= render_slot(@inner_block) %>
                      <Margin.y id={:page_footer_top} />
                    </div>
                    <%= if @include_right_sidepadding? do %>
                      <div class="w-0 md:w-sidepadding"></div>
                    <% end %>
                  </div>
                </div>
                <div class="bg-white">
                  <.content_footer />
                </div>
              </div>
            </div>
            <div class="pb-0 lg:pb-10 bg-grey5">
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
