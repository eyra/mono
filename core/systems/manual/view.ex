defmodule Systems.Manual.View do
  use CoreWeb, :embedded_live_view
  use Frameworks.Pixel
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Toolbar
  alias Systems.Manual

  def dependencies(),
    do: [:manual_id, :title, :current_user, :presentation, {:user_state, [:chapter, :page]}]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{manual_id: manual_id}}) do
    Manual.Public.get_manual!(manual_id, Manual.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> publish_toolbar_buttons()}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
    |> publish_toolbar_buttons()
  end

  # Modal presentation: publish buttons to parent modal
  defp publish_toolbar_buttons(
         %{assigns: %{presentation: :modal, vm: %{buttons: buttons}}} = socket
       ) do
    publish_event(socket, {:update_modal_buttons, %{buttons: buttons}})
  end

  # Embedded presentation: buttons are rendered locally via vm.toolbar
  defp publish_toolbar_buttons(socket) do
    socket
  end

  # Handle toolbar actions (forwarded from modal)
  @impl true
  def handle_info({:toolbar_action, action}, socket) do
    {:noreply, handle_toolbar_action(action, socket)}
  end

  defp handle_toolbar_action(:back, socket) do
    clear_selected_chapter(socket)
  end

  defp handle_toolbar_action(:done, socket) do
    socket
    |> clear_selected_chapter()
    |> publish_event(:done)
  end

  defp handle_toolbar_action(:next_page, %{assigns: %{vm: vm, user_state: user_state}} = socket) do
    page_id = user_state[:page]
    pages = get_sorted_pages(vm.selected_chapter)
    next_page_id = next_page_id(pages, page_id)
    select_page(socket, next_page_id)
  end

  defp handle_toolbar_action(
         :previous_page,
         %{assigns: %{vm: vm, user_state: user_state}} = socket
       ) do
    page_id = user_state[:page]
    pages = get_sorted_pages(vm.selected_chapter)
    previous_page_id = previous_page_id(pages, page_id)
    select_page(socket, previous_page_id)
  end

  defp get_sorted_pages(%{pages: [_ | _] = pages}),
    do: Enum.sort_by(pages, & &1.userflow_step.order)

  defp get_sorted_pages(_), do: []

  defp next_page_id(pages, current_page_id) do
    current_index = Enum.find_index(pages, &(&1.id == current_page_id)) || 0
    next_index = min(current_index + 1, length(pages) - 1)
    Enum.at(pages, next_index).id
  end

  defp previous_page_id(pages, current_page_id) do
    current_index = Enum.find_index(pages, &(&1.id == current_page_id)) || 0
    previous_index = max(current_index - 1, 0)
    Enum.at(pages, previous_index).id
  end

  # Handle events from child components (upstream)
  @impl true
  def consume_event(%{name: :select_chapter, payload: %{chapter_id: chapter_id}}, socket) do
    {:stop, select_chapter(socket, chapter_id)}
  end

  def consume_event(%{name: :back}, socket) do
    {:stop, clear_selected_chapter(socket)}
  end

  def consume_event(%{name: :close}, socket) do
    {:continue, socket}
  end

  def consume_event(%{name: :done}, socket) do
    {:continue, socket}
  end

  def consume_event(%{name: :page_changed, payload: %{page_id: page_id}}, socket) do
    {:stop, select_page(socket, page_id)}
  end

  # Handle toolbar actions from local Toolbar (embedded presentation)
  def consume_event(%{name: :toolbar_action, payload: %{action: action}}, socket) do
    {:stop, handle_toolbar_action(action, socket)}
  end

  # State management
  defp select_chapter(socket, chapter_id) do
    socket
    |> update_user_state(%{chapter: chapter_id, page: nil})
    |> update_view_model()
    |> publish_toolbar_buttons()
    |> publish_user_state_change(:chapter, chapter_id)
    |> publish_user_state_change(:page, nil)
  end

  defp clear_selected_chapter(socket) do
    socket
    |> update_user_state(%{chapter: nil, page: nil})
    |> update_view_model()
    |> publish_toolbar_buttons()
    |> publish_user_state_change(:chapter, nil)
    |> publish_user_state_change(:page, nil)
  end

  defp select_page(socket, page_id) do
    socket
    |> update_user_state(%{page: page_id})
    |> update_view_model()
    |> publish_toolbar_buttons()
    |> publish_user_state_change(:page, page_id)
  end

  defp update_user_state(socket, updates) do
    current = Map.get(socket.assigns, :user_state, %{})
    assign(socket, :user_state, Map.merge(current, updates))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="manual-view" class="flex flex-col min-h-0 h-full">
      <div class="flex-1 min-h-0 overflow-y-auto">
        <%= if @vm.chapter_view do %>
          <.element {Map.from_struct(@vm.chapter_view)} socket={@socket} />
        <% else %>
          <.element {Map.from_struct(@vm.chapter_list_view)} socket={@socket} />
        <% end %>
      </div>
      <%= if @vm.toolbar do %>
        <div class="flex-shrink-0">
          <.live_component
            module={Toolbar}
            id="manual_toolbar"
            buttons={@vm.toolbar.buttons}
          />
        </div>
      <% end %>
    </div>
    """
  end
end
