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

  defp flex_options(:radio), do: "flex-col gap-3"
  defp flex_options(:checkbox), do: "flex-row flex-wrap gap-x-8 gap-y-3 items-center"
  defp flex_options(_), do: "flex-row flex-wrap gap-3 items-center"

  defp multiselect?(:radio), do: false
  defp multiselect?(_), do: true

  def handle_event("toggle", %{"item" => item_id}, socket) do
    active_item_ids =
      socket
      |> update_items(item_id)
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

  defp get_active_item_ids(items) do
    items
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.id)
  end

  defp update_items(%{assigns: %{items: items}} = socket, item_id_to_toggle) do
    items
    |> Enum.map(&toggle(socket, &1, item_id_to_toggle))
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
    <div class="flex {{ flex_options(@type) }}">
      <For each={{ {item, _} <- Enum.with_index(@items) }}>
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
