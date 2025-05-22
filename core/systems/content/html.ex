defmodule Systems.Content.Html do
  use CoreWeb, :html
  import CoreWeb.Layouts.Workspace.Html, only: [workspace: 1]
  import CoreWeb.Layouts.Website.Html, only: [website: 1]
  import CoreWeb.Layouts.Stripped.Html, only: [stripped: 1]
  import CoreWeb.UI.Popup
  alias Frameworks.Pixel.ModalView
  import CoreWeb.UI.PlainDialog
  alias Frameworks.Pixel.Tabbed
  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Breadcrumbs

  attr(:items, :list, required: true)
  attr(:target, :any, default: "")

  def context_menu(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
        <div
          id="context-menu-items"
          class="rounded-lg shadow-floating p-6 w-[240px] bg-white hidden"
        >
          <div class="flex flex-col gap-6 items-left">
            <%= for item <- @items do %>
              <div
                phx-target={@target}
                phx-click="context_menu_item_click"
                phx-value-item={item.id}
                class="flex-wrap cursor-pointer text-grey1 hover:text-primary">
                <button class="text-button font-button">
                  <%= item.label %>
                </button>
              </div>
            <% end %>
          </div>
        </div>
        <div class="flex flex-row">
          <div class="flex-grow" />
          <div
            id="context-menu-button"
            phx-hook="Toggle"
            target="context-menu-items"
            class="flex-shrink-0 w-10 h-10 flex flex-col items-center justify-center text-primary bg-white rounded-full shadow-floating active:shadow-none cursor-pointer"
          >
            <div class="text-title5 font-title5 text-primary pointer-events-none">i</div>
          </div>
        </div>
      </div>
    """
  end

  attr(:modals, :map, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  def live_block(assigns) do
    ~H"""
    <div>
      <.popup_block popup={@popup} />
      <.plain_dialog_block dialog={@dialog} />
      <ModalView.dynamic modals={@modals} />
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  slot(:top_bar)
  slot(:inner_block, required: true)

  def live_workspace(assigns) do
    ~H"""
    <.workspace title={@title} menus={@menus} >
      <:top_bar>
        <%= render_slot(@top_bar) %>
      </:top_bar>

      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>

      <%= render_slot(@inner_block) %>
    </.workspace>
    """
  end

  attr(:user, :map, required: true)
  attr(:user_agent, :map, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:include_right_sidepadding?, :boolean, default: true)

  slot(:hero, required: true)
  slot(:inner_block, required: true)

  def live_website(assigns) do
    ~H"""
    <.website user={@user} include_right_sidepadding?={@include_right_sidepadding?} user_agent={@user_agent} menus={@menus} >
      <:hero>
        <%= render_slot(@hero) %>
      </:hero>

      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>

      <%= render_slot(@inner_block) %>
    </.website>
    """
  end

  attr(:title, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)

  slot(:inner_block, required: true)

  def live_stripped(assigns) do
    ~H"""
    <.stripped title={@title} menus={@menus} >
      <.live_block modals={@modals} popup={@popup} dialog={@dialog}/>
      <%= render_slot(@inner_block) %>
    </.stripped>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)

  def tabbar_page(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
        <%= if Enum.count(@tabs) > 0 do %>
          <Navigation.tabbar>
            <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
          </Navigation.tabbar>

          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content tabs={@tabs} include_top_margin={false} />
          </div>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)
  attr(:breadcrumbs, :list, default: [])

  def tabbar_page_breadcrumbs(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
        <%= if Enum.count(@tabs) > 0 do %>
          <div class="flex flex-row items-center justify-between w-full h-navbar-height">
            <Area.content>
              <div class="flex flex-col gap-y-4 mt-4 sm:mt-0 sm:flex-row w-full justify-between">
                  <div>
                    <%= if Enum.count(@breadcrumbs || []) > 0 do %>
                      <.live_component id="path" module={Breadcrumbs} elements={@breadcrumbs}/>
                    <% end %>
                  </div>
                  <div class="flex justify-center">
                    <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
                  </div>
                  <div class=""></div>
              </div>
            </Area.content>
          </div>
          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
              <Tabbed.content tabs={@tabs} include_top_margin={false} />
          </div>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modals, :list, required: true)
  attr(:popup, :map, required: true)
  attr(:dialog, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:tabbar_size, :atom, required: true)
  attr(:show_errors, :string, required: true)
  attr(:actions, :list, required: true)
  attr(:more_actions, :list, default: [])
  attr(:breadcrumbs, :list, required: true)

  def management_page(assigns) do
    ~H"""
      <div id={:content_management_page} phx-hook="Viewport">
        <.live_workspace title={@title} menus={@menus} modals={@modals} popup={@popup} dialog={@dialog}>
          <:top_bar>
            <Navigation.action_bar breadcrumbs={@breadcrumbs} right_bar_buttons={@actions} more_buttons={@more_actions}>
              <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} size={@tabbar_size} />
            </Navigation.action_bar>
          </:top_bar>

          <div id="content_management_live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content tabs={@tabs} />
          </div>
          <Tabbed.footer tabs={@tabs} />
        </.live_workspace>
      </div>
    """
  end
end
