defmodule Systems.Home.AdvertsView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Logo
  alias Frameworks.Pixel.Text
  alias Systems.Advert

  @impl true
  def update(%{title: title, cards: cards} = params, %{assigns: %{}} = socket) do
    sub_heading_text = dgettext("link-advert", "submission.available.sub_heading")

    {
      :ok,
      socket
      |> assign(
        title: title,
        cards: cards,
        count: Map.get(params, :count, Enum.count(cards)),
        more_path: Map.get(params, :more_path),
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
            <span class="text-primary"> <%= @count %></span>
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
      <%= if not Enum.empty?(@cards) do %>
        <.spacing value="M" />
      <% end %>
      <Grid.dynamic>
        <%= for card <- @cards do %>
          <Advert.CardView.dynamic card={card} target={@myself}/>
        <% end %>
      </Grid.dynamic>
      <%= if @more_path && @count > Enum.count(@cards) do %>
        <.spacing value="M" />
        <div class="flex flex-row justify-end">
          <.link navigate={@more_path}>
            <div class="flex flex-row items-center gap-2 text-button font-button text-primary">
              <%= dgettext("eyra-home", "studies.show_more") %>
              <img src={~p"/images/icons/forward.svg"} alt="" />
            </div>
          </.link>
        </div>
      <% end %>
    </div>
    """
  end
end
