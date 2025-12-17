defmodule CoreWeb.Layouts.Stripped.Html do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import Phoenix.Component
  import CoreWeb.UI.Footer
  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Hero

  attr(:title, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:footer?, :boolean, default: true)

  attr(:privacy_text, :string, default: dgettext("eyra-ui", "privacy.link"))
  attr(:terms_text, :string, default: dgettext("eyra-ui", "terms.link"))

  slot(:header)
  slot(:inner_block, required: true)

  def stripped(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-1">
        <div id="main-content" class="flex flex-col w-full h-viewport">
            <div class="flex-wrap lg:hidden">
              <Navigation.mobile_navbar {@menus.mobile_navbar} />
            </div>
            <div class="flex-wrap hidden lg:flex">
              <Navigation.desktop_navbar {@menus.desktop_navbar} />
            </div>
          <div class="flex-1">
            <div class="flex flex-col h-full border-t border-b border-grey4">
              <%= render_slot(@header) %>
              <%= if @title do %>
                <div class="flex-none">
                  <Hero.illustration2 title={@title} />
                </div>
              <% end %>
              <div class="flex-1 min-h-0 bg-white">
                <div class="flex flex-row w-full h-full min-h-0">
                  <div id="layout-inner-block" class="flex-1 h-full min-h-0">
                    <%= render_slot(@inner_block) %>
                    <Margin.y id={:page_footer_top} />
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
            <.platform_footer privacy_text={@privacy_text} terms_text={@terms_text} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
