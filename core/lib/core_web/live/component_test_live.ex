defmodule CoreWeb.ComponentTestLive do
  use CoreWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    component_module = session["component_module"]
    component_type = session["component_type"] || :function_component
    component_id = session["component_id"] || "test-component"
    component_props = session["component_props"] || %{}
    component_events = session["component_events"] || []

    {:ok,
     socket
     |> assign(:component_module, component_module)
     |> assign(:component_type, component_type)
     |> assign(:component_id, component_id)
     |> assign(:component_props, component_props)
     |> assign(:component_events, component_events)
     |> assign(:event_log, [])}
  end

  @impl true
  def handle_info({event_name, payload}, socket) do
    # Log any events sent from child components
    event_entry = %{
      time: DateTime.utc_now(),
      event: event_name,
      payload: payload
    }

    {:noreply, update(socket, :event_log, &[event_entry | &1])}
  end

  @impl true
  def handle_event(event_name, params, socket) do
    # Log and potentially forward events
    event_entry = %{
      time: DateTime.utc_now(),
      event: event_name,
      params: params
    }

    socket = update(socket, :event_log, &[event_entry | &1])

    # If this event is configured to update component props, do so
    if event_name in socket.assigns.component_events do
      # Allow tests to define how events update props
      updated_props = handle_configured_event(event_name, params, socket.assigns.component_props)
      {:noreply, assign(socket, :component_props, updated_props)}
    else
      {:noreply, socket}
    end
  end

  # Example event handlers for common patterns
  defp handle_configured_event("active_item_ids", %{"active_item_ids" => ids}, props) do
    # Update items based on active IDs
    items =
      Enum.map(props.items || [], fn item ->
        Map.put(item, :active, "#{item.id}" in ids)
      end)

    Map.put(props, :items, items)
  end

  defp handle_configured_event("active_item_id", %{"active_item_id" => id}, props) do
    # Update single active item
    items =
      Enum.map(props.items || [], fn item ->
        Map.put(item, :active, "#{item.id}" == id)
      end)

    Map.put(props, :items, items)
  end

  defp handle_configured_event(_event, _params, props), do: props

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="mb-8 border-b pb-4">
        <h1 class="text-2xl font-bold mb-2">Component Test Harness</h1>
        <div class="text-sm text-gray-600">
          <%= if @component_module do %>
            <div>Module: <code class="bg-gray-100 px-2 py-1 rounded"><%= inspect(@component_module) %></code></div>
            <div>Type: <code class="bg-gray-100 px-2 py-1 rounded"><%= @component_type %></code></div>
            <div>ID: <code class="bg-gray-100 px-2 py-1 rounded"><%= @component_id %></code></div>
          <% else %>
            <div class="text-yellow-600">
              No component configured. Pass component configuration via session params in your test.
            </div>
          <% end %>
        </div>
      </div>

      <%= if @component_module do %>
        <div class="mb-8">
          <h2 class="text-lg font-semibold mb-4">Component Render</h2>
          <div class="border rounded-lg p-6 bg-gray-50">
            <%= render_test_component(assigns) %>
          </div>
        </div>

        <div class="mb-8">
          <h2 class="text-lg font-semibold mb-4">Component Props</h2>
          <div class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto">
            <pre><code><%= Jason.encode!(@component_props, pretty: true) %></code></pre>
          </div>
        </div>

        <%= if @event_log != [] do %>
          <div class="mb-8">
            <h2 class="text-lg font-semibold mb-4">Event Log</h2>
            <div class="space-y-2">
              <%= for event <- Enum.take(@event_log, 10) do %>
                <div class="border rounded p-3 bg-white">
                  <div class="text-sm text-gray-500"><%= Calendar.strftime(event.time, "%H:%M:%S.%f") %></div>
                  <div class="font-medium"><%= event.event %></div>
                  <div class="text-sm text-gray-700">
                    <pre><%= inspect(Map.get(event, :payload) || Map.get(event, :params), pretty: true, limit: :infinity) %></pre>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      <% else %>
        <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center text-gray-500">
          <div class="mb-4">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
            </svg>
          </div>
          <h3 class="text-lg font-medium mb-2">No Component Loaded</h3>
          <p class="text-sm mb-4">Pass component configuration via session params in your test.</p>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper function to render the component based on its type
  defp render_test_component(%{component_type: :live_component} = assigns) do
    ~H"""
    <.live_component
      module={@component_module}
      id={@component_id}
      {@component_props}
    />
    """
  end

  defp render_test_component(%{component_type: :function_component} = assigns) do
    ~H"""
    <%= apply(@component_module, :render, [Map.merge(assigns, @component_props)]) %>
    """
  end

  defp render_test_component(assigns) do
    ~H"""
    <div class="text-red-600">
      Unknown component type: <%= @component_type %>
    </div>
    """
  end
end
