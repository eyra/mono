defmodule CoreWeb.Layouts.Stripped.Component do
  @moduledoc """
    Wrapper component used at the root of a page to create a menu + detail layout
  """
  use Surface.Component

  import EyraUI.Components.OldSkool

  alias EyraUI.Navigation.{DesktopNavbar, MobileNavbar}

  prop(user, :string, required: true)
  prop(active_item, :any, required: true)

  slot(default, required: true)

  defp builder, do: Application.fetch_env!(:core, :stripped_menu_builder)

  defp build_menu(type, socket) do
    builder().build_menu(
      type,
      socket,
      socket.assigns.__assigns__.user,
      socket.assigns.__assigns__.active_item,
      nil
    )
  end

  def render(assigns) do
    ~H"""
      <div>
        <div class="flex flex-col w-full h-screen">
          <div class="flex-wrap">
            <MobileNavbar items={{ build_menu(:mobile_navbar, @socket) }} path_provider={{ CoreWeb.Router.Helpers }} />
            <DesktopNavbar items={{ build_menu(:desktop_navbar, @socket) }} path_provider={{ CoreWeb.Router.Helpers }} />
          </div>
          <div class="bg-white flex-grow">
            <slot />
          </div>
          <div class="pb-0 md:pb-10 bg-grey5">
            <div class="bg-white">
              {{ footer CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-left.svg"), CoreWeb.Router.Helpers.static_path(@socket, "/images/footer-right.svg") }}
            </div>
          </div>
        </div>
      </div>
    """
  end
end
