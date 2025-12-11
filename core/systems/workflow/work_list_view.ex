defmodule Systems.Workflow.WorkListView do
  use CoreWeb, :live_component
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Workflow.HTML, only: [work_list_item: 1]

  alias Frameworks.Pixel.Button

  @impl true
  def update(%{id: id, work_list: %{items: items, selected_item_id: selected_item_id}}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        items: items,
        selected_item_id: selected_item_id,
        done_button: %{
          action: %{type: :send, event: "done"},
          face: %{
            type: :plain,
            icon: :forward,
            icon_align: :right,
            label: dgettext("eyra-workflow", "work_list.done.button")
          }
        }
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
      {:noreply, socket |> publish_event({:work_item_selected, payload})}
    end
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, socket |> publish_event(:work_done)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <div class="flex flex-col gap-2">
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <.work_list_item {item} index={index} selected?={item.id == @selected_item_id} target={@myself} />
        <% end %>
      </div>
      <.spacing value="M" />
      <div class="flex flex-row">
        <div class="flex-grow" />
        <Button.dynamic {@done_button} />
        <div class="flex-grow" />
      </div>
    </div>
    """
  end
end
