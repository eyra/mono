defmodule CoreWeb.Layouts.Stripped.Html do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer
  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Hero

  attr(:title, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:footer?, :boolean, default: true)

  slot(:header)
  slot(:inner_block, required: true)

  def stripped(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="w-0 md:w-sidepadding flex-shrink-0">
      </div>
      <div class="flex-1">
        <div id="main-content" class="flex flex-col w-full h-viewport">
            <div class="flex-wrap md:hidden">
              <Navigation.mobile_navbar {@menus.mobile_navbar} />
            </div>
            <div class="flex-wrap hidden md:flex">
              <Navigation.desktop_navbar {@menus.desktop_navbar} />
            </div>
          <div class="flex-1">
            <div class="flex flex-col h-full border-t border-l border-b border-grey4">
              <%= render_slot(@header) %>
              <%= if @title do %>
                <div class="flex-none">
                  <Hero.small title={@title} />
                </div>
              <% end %>
              <div class="flex-1 bg-white">
                <div class="flex flex-row w-full h-full">
                  <div id="layout-inner-block" class="flex-1">
                    <%= render_slot(@inner_block) %>
                    <Margin.y id={:page_footer_top} />
                  </div>
                  <div class="w-0 md:w-sidepadding flex-shrink-0">
                  </div>
                </div>
              </div>
              <%= if @footer? do %>
                <div class="bg-white">
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
    """
  end
end
