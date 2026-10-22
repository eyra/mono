defmodule Systems.Desktop.View do
  use CoreWeb, :live_component_fabric

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Text
  alias Systems.NextAction
  alias Systems.Project

  @impl true
  def update(%{vm: vm}, socket) do
    {:ok, socket |> assign(vm: vm)}
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{vm: %{content_items: content_items}}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(content_items, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
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
        <Margin.y id={:title2_bottom} />
        <Grid.dynamic>
          <%= for card <- @vm.content_items do %>
            <Project.CardView.dynamic card={card} />
          <% end %>
        </Grid.dynamic>
      </Area.content>
    </div>
    """
  end
end
