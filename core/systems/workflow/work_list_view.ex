defmodule Systems.Workflow.WorkListView do
  use CoreWeb, :live_component

  import Systems.Workflow.ItemViews, only: [work_item: 1]

  @impl true
  def update(%{id: id, work_list: %{items: items, selected_item_id: selected_item_id}}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        items: items,
        selected_item_id: selected_item_id
      )
    }
  end

  @impl true
  def handle_event(
        "work_item_selected",
        %{"item" => item_id} = payload,
        %{assigns: %{selected_item_id: selected_item_id}} = socket
      ) do
    if String.to_integer(item_id) == selected_item_id do
      {:noreply, socket}
    else
      {:noreply, socket |> send_event(:parent, "work_item_selected", payload)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <div class="flex flex-col gap-2">
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <.work_item {item} index={index} selected?={item.id == @selected_item_id} target={@myself} />
        <% end %>
      </div>
    </div>
    """
  end
end
