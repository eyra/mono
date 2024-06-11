defmodule Systems.Desktop.View do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Content
  alias Frameworks.Pixel.Text
  alias Systems.NextAction

  @impl true
  def update(%{vm: vm}, socket) do
    {:ok, socket |> assign(vm: vm)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @vm.next_best_action do %>
          <div>
            <NextAction.View.highlight {@vm.next_best_action} />
            <.spacing value="XL" />
          </div>
        <% end %>
        <Text.title2>
          <%= dgettext("eyra-dashboard", "recent-items.title") %>
          <span class="text-primary"> <%= Enum.count(@vm.content_items) %></span>
        </Text.title2>
        <.list items={@vm.content_items} />
      </Area.content>
    </div>
    """
  end
end
