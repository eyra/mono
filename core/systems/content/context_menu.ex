defmodule Systems.Content.ContextMenu do
  use CoreWeb, :live_component

  @impl true
  def update(%{items: items}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket |> assign(items: items)
    }
  end

  @impl true
  def handle_event("click", %{"item" => item_id}, socket) do
    item_id = String.to_existing_atom(item_id)
    {:noreply, socket |> send_event(:parent, "show", %{page: item_id})}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-col gap-4">
        <div
          id="context-menu-items"
          class="rounded-lg shadow-floating p-6 w-[240px] bg-white hidden"
        >
          <div class="flex flex-col gap-6 items-left">
            <%= for item <- @items do %>
              <div
                phx-target={@myself}
                phx-click="click"
                phx-value-item={item.id}
                class="flex-wrap cursor-pointer text-grey1 hover:text-primary">
                <button class="text-button font-button">
                  <%= item.label %>
                </button>
              </div>
            <% end %>
          </div>
        </div>
        <div class="flex flex-row">
          <div class="flex-grow" />
          <div
            id="context-menu-button"
            phx-hook="Toggle"
            target="context-menu-items"
            class="flex-shrink-0 w-10 h-10 flex flex-col items-center justify-center text-primary bg-white rounded-full shadow-floating active:shadow-none cursor-pointer"
          >
            <div class="text-title5 font-title5 text-primary text-grey1 pointer-events-none">i</div>
          </div>
        </div>
      </div>
    """
  end
end
