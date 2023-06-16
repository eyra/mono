defmodule Systems.Project.NodePage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :projects
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Layouts.Workspace.Component

  alias Frameworks.Pixel.Grid

  alias Systems.{
    Project
  }

  def mount(%{"id" => id}, _session, socket) do
    model = %{id: String.to_integer(id), director: :project}

    {
      :ok,
      socket
      |> assign(model: model)
      |> observe_view_model()
      |> update_menus()
    }
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{vm: %{item_cards: item_cards, node_cards: node_cards}}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(item_cards ++ node_cards, &(&1.id == card_id))
    {:noreply, push_redirect(socket, to: path)}
  end

  @doc """
    ## Attributes
      - vm: Observed view model: title, node_cards, item_cards
        See Systems.Project.NodePageBuilder for more detailed information
  """
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={@vm.title} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if Enum.count(@vm.node_cards) > 0 do %>
          <div class="flex flex-row items-center justify-center">
            <div class="h-full">
              <Text.title2 margin="">
                <%= dgettext("eyra-project", "node.nodes.title") %>
                <span class="text-primary"> <%= Enum.count(@vm.node_cards) %></span>
              </Text.title2>
            </div>
            <div class="flex-grow">
            </div>
            <div class="h-full pt-2px lg:pt-1">
              <Button.Action.send event="create_item">
                <div class="sm:hidden">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.node.button.short")} icon={:forward} />
                </div>
                <div class="hidden sm:block">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.node.button")} icon={:forward} />
                </div>
              </Button.Action.send>
            </div>
          </div>
          <Margin.y id={:title2_bottom} />
          <Grid.dynamic>
            <%= for card <- @vm.node_cards do %>
              <Project.CardView.dynamic card={card} />
            <% end %>
          </Grid.dynamic>
          <.spacing value="L" />
        <% end %>

        <%= if Enum.count(@vm.item_cards) > 0 do %>
        <div class="flex flex-row items-center justify-center">
            <div class="h-full">
              <Text.title2 margin="">
                <%= dgettext("eyra-project", "node.items.title") %>
                <span class="text-primary"> <%= Enum.count(@vm.item_cards) %></span>
              </Text.title2>
            </div>
            <div class="flex-grow">
            </div>
            <div class="h-full pt-2px lg:pt-1">
              <Button.Action.send event="create_item">
                <div class="sm:hidden">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.item.button.short")} icon={:forward} />
                </div>
                <div class="hidden sm:block">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.item.button")} icon={:forward} />
                </div>
              </Button.Action.send>
            </div>
          </div>
          <Margin.y id={:title2_bottom} />
          <Grid.dynamic>
            <%= for card <- @vm.item_cards do %>
              <Project.CardView.dynamic card={card} />
            <% end %>
          </Grid.dynamic>
          <.spacing value="L" />
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
