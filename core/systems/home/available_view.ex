defmodule Systems.Home.AvailableView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Grid
  alias Systems.Advert

  @impl true
  def update(%{title: title, cards: cards}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket |> assign(title: title, cards: cards)
    }
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{cards: cards}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(cards, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-2 border-grey4 rounded p-6">
      <div class="flex flex-row">
        <Text.title2 margin="">
          <%= @title %>
          <span class="text-primary"> <%= Enum.count(@cards) %></span>
        </Text.title2>
        <div class="flex-grow" />
        <div>
          <img class="h-12" src="/images/panl-wide.svg" />
        </div>
      </div>
      <%= if not Enum.empty?(@cards) do %>
        <.spacing value="M" />
      <% end %>
      <Grid.dynamic>
        <%= for card <- @cards do %>
          <Advert.CardView.dynamic card={card} target={@myself}/>
        <% end %>
      </Grid.dynamic>
    </div>
    """
  end
end
