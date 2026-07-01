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
        <div class="bg-grey5 lg:px-16">
          <div id="main-content" class="flex flex-col w-full min-h-viewport md:h-viewport lg:max-w-[1536px] lg:mx-auto">
              <div class="flex-wrap lg:hidden">
                <Navigation.mobile_navbar {@menus.mobile_navbar} />
              </div>
              <div class="flex-wrap hidden lg:flex">
                <Navigation.desktop_navbar {@menus.desktop_navbar} />
              </div>
            <div class="flex-1 flex flex-col lg:relative lg:z-10">
              <div class="flex-1 flex flex-col min-h-0 bg-white lg:shadow-prism-container">
                <%= render_slot(@header) %>
                <%= if @title do %>
                  <div class="flex-none">
                    <Hero.illustration2 title={@title} />
                  </div>
                <% end %>
                <div id="layout-inner-block" class="flex-1 h-full min-h-0">
                  <%= render_slot(@inner_block) %>
                  <Margin.y id={:page_footer_top} />
                </div>
                <%= if @footer? do %>
                  <.content_footer />
                <% end %>
              </div>
            </div>
            <div class="bg-grey5">
              <.platform_footer privacy_text={@privacy_text} terms_text={@terms_text} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
