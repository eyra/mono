defmodule Systems.Home.AdvertsView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Logo
  alias Frameworks.Pixel.Text
  alias Systems.Advert

  @max_visible 6

  @impl true
  def update(%{title: title, cards: cards}, %{assigns: %{}} = socket) do
    sub_heading_text = dgettext("link-advert", "submission.available.sub_heading")
    visible_cards = Enum.take(cards, @max_visible)

    {
      :ok,
      socket
      |> assign(
        title: title,
        cards: cards,
        visible_cards: visible_cards,
        sub_heading_text: sub_heading_text
      )
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
    <div class="border-2 border-grey4 rounded p-6" data-testid="adverts">
      <div class="flex flex-col">
        <div class="flex flex-row items-center">
          <Text.title2 margin="">
            <%= @title %>
            <span class="text-primary"> <%= Enum.count(@cards) %></span>
          </Text.title2>
          <div class="flex-grow" />
          <div>
            <Logo.product name={:panl} variant={:wide} class="h-12" />
          </div>
        </div>
        <.spacing value="S" />
        <div>
          <Text.body>
            <%= @sub_heading_text %>
          </Text.body>
        </div>
      </div>
      <%= if not Enum.empty?(@visible_cards) do %>
        <.spacing value="M" />
      <% end %>
      <Grid.dynamic>
        <%= for card <- @visible_cards do %>
          <Advert.CardView.dynamic card={card} target={@myself}/>
        <% end %>
      </Grid.dynamic>
    </div>
    """
  end
end
