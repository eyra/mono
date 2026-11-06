defmodule Next.Systems.Announcement.AdminView do
  @moduledoc """
  The Announcements tab on the Admin page: the list of announcements. A row
  opens its announcement, and New announcement a new one, on the page to
  compose it (`Next.Systems.Announcement.ComposePage`).

  Only system admins with the `announcements` flag on see the list
  (`@vm.allowed?`).
  """
  use MicaWeb, :embedded_live_view

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Phoenix.LiveView.JS
  alias Systems.Observatory

  def dependencies(), do: [:current_user, :locale]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(%{vm: %{allowed?: false}} = assigns) do
    ~H"""
    <div data-testid="announcement-admin-view"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div data-testid="announcement-admin-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-center">
          <Text.title2 margin="">
            <%= @vm.title %> <span class="text-primary"><%= @vm.count %></span>
          </Text.title2>
          <div class="flex-grow" />
          <div class="h-full pt-2px lg:pt-1">
            <Button.dynamic {@vm.new_button} testid="new-announcement-button" />
          </div>
        </div>
        <.spacing value="M" />

        <%= if @vm.items == [] do %>
          <Text.body_large><%= @vm.empty_text %></Text.body_large>
        <% else %>
          <.announcement_list head_cells={@vm.head_cells} items={@vm.items} />
        <% end %>
      </Area.content>
    </div>
    """
  end

  attr(:head_cells, :list, required: true)
  attr(:items, :list, required: true)

  defp announcement_list(assigns) do
    ~H"""
    <table class="w-full table-fixed text-left" data-testid="announcement-list">
      <thead>
        <tr class="h-8 text-tablehead font-tablehead text-grey2">
          <%= for cell <- @head_cells do %>
            <th><%= cell %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr
            class="h-12 border-t border-grey4 font-body text-bodysmall cursor-pointer hover:bg-grey5"
            phx-click={JS.navigate(item.path)}
            data-testid={"announcement-row-#{item.id}"}
          >
            <td><%= item.kind %></td>
            <td class="truncate pr-4"><%= item.title %></td>
            <td><%= item.priority %></td>
            <td><%= item.published %></td>
            <td><%= item.recipient_count %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
