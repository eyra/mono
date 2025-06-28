defmodule Systems.Onyx.ConceptTab do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view
  use CoreWeb.UI
  use Frameworks.Pixel

  alias Frameworks.Pixel.Grid

  alias Systems.Onyx

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"title" => title, "concepts" => concepts, "user" => user, "depth" => depth},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        title: title,
        concepts: concepts,
        user: user,
        depth: depth
      )
      |> update_cards()
    }
  end

  defp update_cards(%{assigns: %{concepts: concepts, depth: depth}} = socket) do
    cards = concepts |> Enum.map(&Onyx.Private.map_to_card(&1, "concept_tab-#{depth}"))
    assign(socket, :cards, cards)
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => id},
        %{assigns: %{user: user, depth: depth}} = socket
      ) do
    concept_id = id |> String.split("-") |> List.last() |> String.to_integer()

    modal =
      LiveNest.Modal.prepare_live_view(
        "concept-modal",
        Systems.Onyx.ConceptView,
        session: [id: concept_id, user: user, depth: depth + 1],
        style: :full
      )

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def render(assigns) do
    ~H"""
     <Area.content>
        <Margin.y id={:page_top} />

        <Text.title2 margin="">
            { @title }<span class="text-primary"> { Enum.count(@cards) }</span>
        </Text.title2>

        <Margin.y id={:title2_bottom} />
      <Grid.dynamic>
        <%= for card <- @cards do %>
          <Onyx.CardView.dynamic card={card}/>
        <% end %>
      </Grid.dynamic>
      <.spacing value="L" />
    </Area.content>
    """
  end
end
