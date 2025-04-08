defmodule CoreWeb.Layouts.App.Html do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb, :html

  import CoreWeb.UI.Footer
  alias Frameworks.Pixel.Navigation

  attr(:user, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:logo, :any)
  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-1">
        <div class="flex flex-col w-full h-viewport">
          <div class="flex-wrap">
            <Navigation.app_navbar
              logo={@logo}
              items={@menus.desktop_navbar}
            />
          </div>
          <div class="flex-1">
            <div class="flex flex-col h-full">
              <div class="flex-1 bg-white border-t border-l border-grey4">
                <%= render_slot(@inner_block) %>
              </div>
              <div class="bg-white border-b border-l border-grey4">
                <.content_footer />
              </div>
              <div class="bg-grey5 h-16 w-full">
                <div class="flex flex-col justify-center items-center h-full">
                  <div class="text-bodysmall font-body text-grey2">
                    Powered by Eyra
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
