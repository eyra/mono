defmodule Systems.Workflow.BuilderView do
  use CoreWeb, :live_component

  require Logger

  import Frameworks.Pixel.SidePanel
  import Systems.Workflow.ItemViews

  alias Systems.Workflow

  @impl true
  def update(
        %{
          id: id,
          title: title,
          description: description,
          workflow: %{items: items} = workflow,
          config: config,
          user: user,
          timezone: timezone,
          uri_origin: uri_origin,
          director: director
        },
        socket
      ) do
    ordering_enabled? = Enum.count(items) > 1

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        description: description,
        workflow: workflow,
        config: config,
        user: user,
        timezone: timezone,
        uri_origin: uri_origin,
        ordering_enabled?: ordering_enabled?,
        director: director
      )
      |> update_render_library()
      |> reset_children()
      |> order_items()
      |> compose_item_cells()
    }
  end

  defp update_render_library(socket) do
    assign(socket, render_library?: true)
  end

  defp compose_item_cells(%{assigns: %{ordered_items: ordered_items}} = socket) do
    Enum.reduce(ordered_items, socket, fn item, socket ->
      compose_child(socket, "item_cell_#{item.id}")
    end)
  end

  @impl true
  def compose(
        "item_cell_" <> item_id,
        %{
          ordered_items: ordered_items,
          ordering_enabled?: ordering_enabled?,
          user: user,
          timezone: timezone,
          uri_origin: uri_origin
        } = assigns
      ) do
    item = find_by_id(ordered_items, item_id)
    title = get_title(item, assigns)
    relative_position = relative_position(item.position, Enum.count(ordered_items))

    %{
      module: Workflow.ItemCell,
      params: %{
        item: item,
        type: title,
        user: user,
        timezone: timezone,
        uri_origin: uri_origin,
        relative_position: relative_position,
        ordering_enabled?: ordering_enabled?
      }
    }
  end

  defp relative_position(0, _count), do: :top
  defp relative_position(position, count) when position == count - 1, do: :bottom
  defp relative_position(_position, _count), do: :middle

  @impl true
  def handle_event(
        "add",
        %{"item" => item_id},
        %{assigns: %{workflow: %{id: id}, director: director}} = socket
      ) do
    item = get_library_item(socket, item_id)

    {:ok, _} = Workflow.Public.add_item(id, item, director)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("delete", %{item: item}, socket) do
    Workflow.Public.delete(item)
    {:noreply, socket}
  end

  @impl true
  def handle_event("up", %{item: %{position: position} = item}, socket) do
    {:ok, _} = Workflow.Public.update_position(item, position - 1)
    {:noreply, socket}
  end

  @impl true
  def handle_event("down", %{item: %{position: position} = item}, socket) do
    {:ok, _} = Workflow.Public.update_position(item, position + 1)
    {:noreply, socket}
  end

  defp order_items(%{assigns: %{workflow: workflow}} = socket) do
    assign(socket, ordered_items: Workflow.Model.ordered_items(workflow))
  end

  defp get_title(%{tool_ref: %{special: special}}, %{config: %{library: %{items: library_items}}}) do
    case Enum.find(library_items, &(&1.special == special)) do
      %{title: title} ->
        title

      nil ->
        Logger.error("No library item found for workflow item with special: #{special}")

        special
        |> Atom.to_string()
        |> String.replace("_", " ")
        |> String.capitalize()
    end
  end

  defp get_library_item(socket, item_id) when is_binary(item_id) do
    get_library_item(socket, String.to_existing_atom(item_id))
  end

  defp get_library_item(%{assigns: %{config: %{library: %{items: items}}}}, item_id)
       when is_atom(item_id) do
    Enum.find(items, &(&1.special == item_id))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div id={:item_builder} class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @title %></Text.title2>
            <Text.body><%= @description %></Text.body>
            <.spacing value="M" />
            <div class="bg-grey5 rounded-2xl p-6 flex flex-col gap-4">
              <%= if @ordering_enabled? do %>
                <Align.horizontal_center>
                  <Text.hint><%= dgettext("eyra-workflow", "item.list.hint") %></Text.hint>
                </Align.horizontal_center>
              <% end %>
              <.stack fabric={@fabric} />
            </div>
          </Area.content>
        </div>
        <%= if @render_library? do %>
          <div class="flex-shrink-0 w-side-panel">
            <.side_panel id={:library} parent={:item_builder}>
              <Margin.y id={:page_top} />
              <.library
                title={dgettext("eyra-workflow", "item.library.title")}
                description={dgettext("eyra-workflow", "item.library.description")}
                items={Enum.map(@config.library.items, &Map.from_struct/1)}
              />
            </.side_panel>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
