defmodule Frameworks.Pixel.Navigation do
  @moduledoc false
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Menu
  alias Frameworks.Pixel.Align

  import Frameworks.Pixel.Line

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def navbar(assigns) do
    ~H"""
    <div class="w-full h-topbar sm:h-topbar-sm lg:h-topbar-lg">
      <Align.horizontal_center>
        <%= if @home do %>
          <div class="flex-wrap">
            <div class="mr-8">
              <Menu.item {@home} />
            </div>
          </div>
        <% end %>
        <%= if @primary do %>
          <%= for item <- @primary do %>
            <div class="mr-1">
              <Menu.item {item} />
            </div>
          <% end %>
        <% end %>
        <div class="flex-grow" />
        <%= if @secondary do %>
          <%= for item <- @secondary do %>
            <div class="ml-1">
              <Menu.item {item} />
            </div>
          <% end %>
        <% end %>
      </Align.horizontal_center>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def tabbar(assigns) do
    ~H"""
    <div>
      <Area.content>
        <div class="flex flex-row items-center justify-center w-full h-navbar-height">
          <div class="flex-wrap">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </Area.content>
      <.line />
    </div>
    """
  end

  attr(:right_bar_buttons, :list, default: [])
  attr(:more_buttons, :list, default: [])
  attr(:hide_seperator, :boolean, default: true)
  slot(:inner_block, required: true)

  def action_bar(%{right_bar_buttons: right_bar_buttons} = assigns) do
    assigns =
      assign(assigns, %{
        has_right_bar_buttons: not Enum.empty?(right_bar_buttons)
      })

    ~H"""
    <div class="relative">
      <div id="action_menu" class="hidden z-50 absolute right-14px -mt-6 top-navbar-height">
        <.action_menu buttons={@more_buttons} />
      </div>
      <div class="absolute top-0 left-0 w-full bg-red">
        <Area.content>
          <div class="overflow-scroll scrollbar-hidden w-full">
            <div class="flex flex-row items-center w-full h-navbar-height">
              <div class="flex-grow">
                <%= render_slot(@inner_block) %> <!-- tabbar -->
              </div>
              <%= if @has_right_bar_buttons do %>
                <%= if not @hide_seperator do %>
                  <div class="flex-wrap px-4">
                    <img src={~p"/images/icons/bar_seperator.svg"} alt="">
                  </div>
                <% end %>
                <div class="flex-wrap h-full">
                  <div class="flex flex-row gap-6 h-full">
                    <%= for button <- @right_bar_buttons do %>
                      <Button.dynamic {button} />
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </Area.content>
        <.line />
      </div>
    </div>
    """
  end

  attr(:buttons, :list, required: true)

  def action_menu(assigns) do
    ~H"""
    <div class="flex flex-col justify-left -gap-1 p-6 rounded bg-white shadow-2xl w-action_menu-width">
      <%= for button <- @buttons do %>
        <Button.dynamic {button} />
      <% end %>
    </div>
    """
  end

  attr(:buttons, :list, required: true)

  def button_bar(assigns) do
    ~H"""
    <div class="flex flex-row gap-4 items-center">
      <%= for button <- @buttons do %>
        <Button.dynamic {button} />
      <% end %>
    </div>
    """
  end

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def desktop_menu(assigns) do
    ~H"""
    <div class="hidden lg:block w-desktop-menu-width h-full pl-10 pr-8 pt-10 pb-desktop-menu-bottom-padding">
      <Menu.generic {assigns} />
    </div>
    """
  end

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def tablet_menu(assigns) do
    ~H"""
      <div class="hidden md:block lg:hidden w-tablet-menu-width h-full pt-10 pb-10">
        <Menu.generic {assigns} align="items-center" />
      </div>
    """
  end

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def mobile_menu(assigns) do
    ~H"""
    <div class="md:hidden bg-white p-6 h-full">
      <Menu.generic {assigns} />
    </div>
    """
  end

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def desktop_navbar(assigns) do
    ~H"""
    <div class="bg-grey5 w-full pr-6">
      <.navbar {assigns} />
    </div>
    """
  end

  attr(:home, :map, default: nil)
  attr(:primary, :map, default: nil)
  attr(:secondary, :map, default: nil)

  def mobile_navbar(assigns) do
    ~H"""
    <div class="md:hidden bg-grey5 w-full pl-6 pr-6">
      <.navbar {assigns} />
    </div>
    """
  end

  attr(:items, :any, required: true)
  attr(:logo, :any)

  def app_navbar(assigns) do
    ~H"""
    <div class="pr-4 flex flex-row gap-4 items-center w-full">
      <%= if @logo do %>
        <div>
          <img src={~p"/images/icons/#{"#{@logo}.svg"}"} alt={@logo} />
        </div>
      <% end %>
      <div class="flex-grow">
        <.navbar {@items} />
      </div>
    </div>
    """
  end
end
