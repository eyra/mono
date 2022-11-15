defmodule CoreWeb.Layouts.App.Component do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use CoreWeb.UI.Component

  import CoreWeb.UI.OldSkool

  alias CoreWeb.UI.Navigation.{DesktopNavbar}

  prop(user, :string, required: true)
  prop(menus, :map, required: true)
  prop(logo, :any)

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row">
      <div class="w-0 md:w-sidepadding flex-shrink-0">
      </div>
      <div class="flex-1">
        <div class="flex flex-col w-full h-viewport">
          <div class="flex-wrap">
            <DesktopNavbar
              logo={@logo}
              items={@menus.desktop_navbar}
              path_provider={CoreWeb.Router.Helpers}
            />
          </div>
          <div class="flex-1">
            <div class="flex flex-col h-full">
              <div class="flex-1 bg-white border-t border-l border-grey4">
                <#slot />
              </div>
              <div class="bg-white border-b border-l border-grey4">
                {footer(
                  assigns,
                  CoreWeb.Endpoint.static_path("/images/footer-left.svg"),
                  CoreWeb.Endpoint.static_path("/images/footer-right.svg")
                )}
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
