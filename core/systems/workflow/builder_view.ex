defmodule Systems.Workflow.BuilderView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.SidePanel

  alias Systems.{
    Workflow
  }

  import Workflow.ItemViews

  @impl true
  def update(%{action: "delete", item: item}, socket) do
    Workflow.Public.delete(item)
    {:ok, socket}
  end

  @impl true
  def update(%{action: "up", item: %{position: position} = item}, socket) do
    {:ok, _} = Workflow.Public.update_position(item, position - 1)
    {:ok, socket}
  end

  @impl true
  def update(%{action: "down", item: %{position: position} = item}, socket) do
    {:ok, _} = Workflow.Public.update_position(item, position + 1)
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          id: id,
          workflow: %{items: items} = workflow,
          config: config,
          user: user,
          uri_origin: uri_origin
        },
        socket
      ) do
    ordering_enabled? = Enum.count(items) > 1

    {
      :ok,
      socket
      |> assign(
        id: id,
        workflow: workflow,
        config: config,
        user: user,
        uri_origin: uri_origin,
        ordering_enabled?: ordering_enabled?
      )
      |> order_items()
      |> update_item_types()
    }
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => item_id},
        %{assigns: %{workflow: %{id: id}, config: %{director: director}}} = socket
      ) do
    item = get_library_item(socket, item_id)
    {:ok, _} = Workflow.Public.add_item(id, item, director)

    {
      :noreply,
      socket
    }
  end

  defp order_items(%{assigns: %{workflow: workflow}} = socket) do
    assign(socket, ordered_items: Workflow.Model.ordered_items(workflow))
  end

  defp update_item_types(%{assigns: %{ordered_items: ordered_items}} = socket) do
    item_types = Enum.map(ordered_items, &get_title(&1, socket))
    assign(socket, item_types: item_types)
  end

  defp get_title(%{tool_ref: %{special: special}}, %{
         assigns: %{config: %{library: %{items: library_items}}}
       }) do
    %{title: title} = Enum.find(library_items, &(&1.id == special))
    title
  end

  defp get_library_item(socket, item_id) when is_binary(item_id) do
    get_library_item(socket, String.to_existing_atom(item_id))
  end

  defp get_library_item(%{assigns: %{config: %{library: %{items: items}}}}, item_id)
       when is_atom(item_id) do
    Enum.find(items, &(&1.id == item_id))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div id={:item_builder} class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @config.list.title %></Text.title2>
            <Text.body><%= @config.list.description %></Text.body>
            <.spacing value="M" />
            <.list items={@ordered_items} types={@item_types} ordering_enabled?={@ordering_enabled?} user={@user} uri_origin={@uri_origin} parent={%{type: __MODULE__, id: @id}} />
          </Area.content>
        </div>
        <%= if @config.library do %>
          <div class="flex-shrink-0 w-side-panel">
            <.side_panel id={:library} parent={:item_builder}>
              <Margin.y id={:page_top} />
              <.library {@config.library} />
            </.side_panel>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
