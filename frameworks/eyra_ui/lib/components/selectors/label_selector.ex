defmodule EyraUI.Selectors.Label do
  defstruct [:id, :value, :active]
end

defmodule EyraUI.Selectors.LabelSelector do
  @moduledoc false
  use Surface.LiveComponent

  prop(labels, :list, required: true)
  prop(parent, :map, required: true)
  prop(multiselect, :boolean, default: true)

  # @callback update_selected_labels(id :: atom, socket :: Socket.t(), labels :: list(String.t())) :: Socket.t()

  def handle_event("toggle", %{"label" => label_id}, socket) do
    active_label_ids =
      socket
      |> update_labels(label_id)
      |> get_active_label_ids()

    update_parent(socket, active_label_ids)
    {:noreply, socket}
  end

  defp update_parent(
         %{assigns: %{parent: parent, id: selector_id, multiselect: multiselect}},
         active_label_ids
       ) do
    if multiselect do
      send_update(parent.type,
        id: parent.id,
        selector_id: selector_id,
        active_label_ids: active_label_ids
      )
    else
      active_label_id = List.first(active_label_ids)

      send_update(parent.type,
        id: parent.id,
        selector_id: selector_id,
        active_label_id: active_label_id
      )
    end
  end

  defp get_active_label_ids(labels) do
    labels
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.id)
  end

  defp update_labels(%{assigns: %{labels: labels}} = socket, label_id_to_toggle) do
    labels
    |> Enum.map(&toggle(socket, &1, label_id_to_toggle))
  end

  defp toggle(%{assigns: %{multiselect: multiselect}}, label, label_id) when is_atom(label_id) do
    if label.id === label_id do
      %{label | active: !label.active}
    else
      if multiselect do
        label
      else
        %{label | active: false}
      end
    end
  end

  defp toggle(socket, label, label_id), do: toggle(socket, label, String.to_atom(label_id))

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center gap-4 flex-wrap">
      <For each={{ {label, _} <- Enum.with_index(@labels) }}>
        <div x-data="{ active: {{ label.active }} }" >
          <div
            x-on:mousedown="active = !active"
            :class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
            class="cursor-pointer rounded-full px-6 py-3 text-label font-label select-none"
            :on-click="toggle"
            phx-value-label="{{ label.id }}"
            phx-target={{@myself}}
          >
            {{ label.value }}
          </div>
        </div>
      </For>
    </div>
    """
  end
end
