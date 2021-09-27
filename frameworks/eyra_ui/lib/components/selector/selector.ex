defmodule EyraUI.Selector.Item do
  defstruct [:id, :value, :active]
end

defmodule EyraUI.Selector.Selector do
  @moduledoc false
  use Surface.LiveComponent

  alias EyraUI.Dynamic

  prop(items, :list, required: true)
  prop(parent, :map, required: true)
  prop(type, :atom, default: :label)
  prop(opts, :string, default: "")

  prop(current_items, :list)

  defp flex_options(:radio), do: "flex-col gap-3"
  defp flex_options(:checkbox), do: "flex-row flex-wrap gap-x-8 gap-y-3 items-center"
  defp flex_options(_), do: "flex-row flex-wrap gap-3 items-center"

  defp multiselect?(:radio), do: false
  defp multiselect?(_), do: true

  def update(%{reset: new_items}, socket) do
    {
      :ok,
      socket
      |> assign(current_items: new_items)
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{current_items: _current_items}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, items: items, parent: parent, type: type, opts: opts}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(items: items)
      |> assign(current_items: items)
      |> assign(parent: parent)
      |> assign(type: type)
      |> assign(opts: opts)
    }
  end

  def handle_event("toggle", %{"item" => item_id}, socket) do
    socket =
      socket
      |> update_items(item_id)

    active_item_ids =
      socket
      |> get_active_item_ids()

    update_parent(socket, active_item_ids)

    {:noreply, socket}
  end

  defp update_parent(
         %{assigns: %{type: type, parent: parent, id: selector_id}},
         active_item_ids
       ) do
    if multiselect?(type) do
      send_update(parent.type,
        id: parent.id,
        selector_id: selector_id,
        active_item_ids: active_item_ids
      )
    else
      active_item_id = List.first(active_item_ids)

      send_update(parent.type,
        id: parent.id,
        selector_id: selector_id,
        active_item_id: active_item_id
      )
    end
  end

  BUN

  defp get_active_item_ids(%{assigns: %{current_items: items}}) do
    items
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.id)
  end

  defp update_items(%{assigns: %{current_items: items}} = socket, item_id_to_toggle) do
    items =
      items
      |> IO.inspect(label: "ITEMS A")
      |> Enum.map(&toggle(socket, &1, item_id_to_toggle))
      |> IO.inspect(label: "ITEMS B")

    socket |> assign(current_items: items)
  end

  defp toggle(%{assigns: %{type: type}}, item, item_id) when is_atom(item_id) do
    if item.id === item_id do
      %{item | active: !item.active}
    else
      if multiselect?(type) do
        item
      else
        %{item | active: false}
      end
    end
  end

  defp toggle(socket, item, item_id), do: toggle(socket, item, String.to_atom(item_id))

  defp item_component(:radio), do: EyraUI.Selector.Radio
  defp item_component(:checkbox), do: EyraUI.Selector.Checkbox
  defp item_component(_), do: EyraUI.Selector.Label

  def render(assigns) do
    ~H"""
    <div class="flex {{ flex_options(@type) }} {{ @opts }}">
      <For each={{ {item, _} <- Enum.with_index(@current_items) }}>
        <div x-data="{ active: {{ item.active }} }" >
          <div
            x-on:mousedown="active = !active"
            class="cursor-pointer select-none"
            :on-click="toggle"
            phx-value-item="{{ item.id }}"
            phx-target={{@myself}}
          >
            <Dynamic component={{ item_component(@type) }} props={{ %{item: item } }} />
          </div>
        </div>
      </For>
    </div>
    """
  end
end
