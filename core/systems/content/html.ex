defmodule Systems.Content.Html do
  use CoreWeb, :html
  import CoreWeb.Layouts.Workspace.Html, only: [workspace: 1]
  import CoreWeb.Layouts.Website.Html, only: [website: 1]
  import CoreWeb.Layouts.Stripped.Html, only: [stripped: 1]
  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Breadcrumbs
  alias Frameworks.Pixel.ModalView
  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Tabbed
  alias Frameworks.Pixel.Text
  alias Systems.Content.Adaptable

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

  attr(:socket, :map, required: true)
  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:modal_toolbar_buttons, :list, default: [])

  slot(:top_bar)
  slot(:inner_block, required: true)

  def live_workspace(assigns) do
    ~H"""
    <.workspace title={@title} menus={@menus} >
      <:top_bar>
        <%= render_slot(@top_bar) %>
      </:top_bar>

      <ModalView.dynamic :if={@modal} modal={@modal} socket={@socket} toolbar_buttons={@modal_toolbar_buttons} />

      <%= render_slot(@inner_block) %>
    </.workspace>
    """
  end

  attr(:socket, :map, required: true)
  attr(:user, :map, required: true)
  attr(:user_agent, :map, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:modal_toolbar_buttons, :list, default: [])
  attr(:include_right_sidepadding?, :boolean, default: true)

  slot(:hero, required: true)
  slot(:inner_block, required: true)

  def live_website(assigns) do
    ~H"""
    <.website user={@user} include_right_sidepadding?={@include_right_sidepadding?} user_agent={@user_agent} menus={@menus} >
      <:hero>
        <%= render_slot(@hero) %>
      </:hero>

      <ModalView.dynamic :if={@modal} modal={@modal} socket={@socket} toolbar_buttons={@modal_toolbar_buttons} />

      <%= render_slot(@inner_block) %>
    </.website>
    """
  end

  attr(:socket, :map, required: true)
  attr(:title, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:modal_toolbar_buttons, :list, default: [])

  slot(:inner_block, required: true)

  def live_stripped(assigns) do
    ~H"""
    <.stripped title={@title} menus={@menus} >
      <ModalView.dynamic :if={@modal} modal={@modal} socket={@socket} toolbar_buttons={@modal_toolbar_buttons} />
      <%= render_slot(@inner_block) %>
    </.stripped>
    """
  end

  attr(:socket, :map, required: true)
  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)

  def tabbar_page(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modal={@modal} socket={@socket}>
        <%= if Enum.count(@tabs) > 1 do %>
          <Navigation.tabbar>
            <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
          </Navigation.tabbar>

          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content socket={@socket} tabs={@tabs} bar_id={@tabbar_id} />
          </div>
        <% else %>
          <%= if Enum.count(@tabs) == 1 do %>
            <% [tab] = @tabs %>
            <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
              <%= if tab[:element] do %>
                <LiveNest.HTML.element socket={@socket} {Map.from_struct(tab.element)} />
              <% end %>
            </div>
          <% end %>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:socket, :map, required: true)
  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)
  attr(:breadcrumbs, :list, default: [])

  def tabbar_page_breadcrumbs(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modal={@modal} socket={@socket}>
        <%= if Enum.count(@tabs) > 0 do %>
          <%!-- Breadcrumb row --%>
          <%= if Enum.count(@breadcrumbs || []) > 0 do %>
            <div class="bg-white">
              <Area.content>
                <div class="py-4">
                  <.live_component id="path" module={Breadcrumbs} elements={@breadcrumbs}/>
                </div>
              </Area.content>
            </div>
            <.line />
          <% end %>

          <%!-- Segmented control row --%>
          <div class="bg-white">
            <Area.content>
              <div class="flex items-center justify-center py-6">
                <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
              </div>
            </Area.content>
          </div>
          <.line />

          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content socket={@socket} tabs={@tabs} bar_id={@tabbar_id} />
          </div>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:socket, :map, required: true)
  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:tabs, :list, required: true)
  attr(:tabbar_id, :atom, required: true)
  attr(:initial_tab, :string, required: true)
  attr(:show_errors, :string, required: true)
  attr(:back_path, :string, default: nil)

  @doc """
  A tabbar page with a title bar that includes an optional back button.
  The title is displayed prominently, with a back arrow if back_path is provided.
  Tabs are centered below the title bar.
  """
  def tabbar_page_title(assigns) do
    ~H"""
      <.live_workspace title={@title} menus={@menus} modal={@modal} socket={@socket}>
        <%= if Enum.count(@tabs) > 0 do %>
          <Area.content>
            <div class="pt-6 pb-4">
              <div class="flex flex-row items-center gap-4">
                <%= if @back_path do %>
                  <a href={@back_path} class="text-grey2 hover:text-primary">
                    <img src={~p"/images/icons/back.svg"} alt="Back" class="w-6 h-6" />
                  </a>
                <% end %>
                <Text.title2><%= @title %></Text.title2>
              </div>
            </div>
          </Area.content>

          <Navigation.tabbar>
            <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} type={:segmented} />
          </Navigation.tabbar>

          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content socket={@socket} tabs={@tabs} bar_id={@tabbar_id} />
          </div>
        <% end %>
      </.live_workspace>
    """
  end

  attr(:socket, :map, required: true)
  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:modal, :map, required: true)
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
        <.live_workspace title={@title} menus={@menus} modal={@modal} socket={@socket}>
          <:top_bar>
            <Navigation.action_bar breadcrumbs={@breadcrumbs} right_bar_buttons={@actions} more_buttons={@more_actions}>
              <Tabbed.bar id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} size={@tabbar_size} />
            </Navigation.action_bar>
          </:top_bar>

          <div id="content_management_live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content socket={@socket} tabs={@tabs} bar_id={@tabbar_id} />
          </div>
          <Tabbed.footer bar_id={@tabbar_id} tabs={@tabs} />
        </.live_workspace>
      </div>
    """
  end

  @doc """
  Adaptable layout that adjusts based on item count.

  See `Systems.Content.Adaptable` for full documentation.
  """
  attr(:socket, :map, required: true)
  attr(:items, :list, required: true)
  attr(:creatables, :list, default: [])
  attr(:tabbar_id, :any, required: true)
  attr(:initial_item, :any, default: nil)
  attr(:empty_state, :map, default: nil)

  def adaptable_layout(assigns) do
    Adaptable.layout(assigns)
  end
end
