defmodule EyraUI.Selectors.Label do
  defstruct [:id, :value, :active]
end

defmodule EyraUI.Selectors.LabelSelector do
  @moduledoc false
  use Surface.Component

  alias EyraUI.Spacing

  prop(labels, :list, required: true)
  prop(target, :any)

  @callback all_labels(socket :: Socket.t()) :: list(String.t())
  @callback update_selected_labels(socket :: Socket.t(), labels :: list(String.t())) :: Socket.t()

  defmacro __using__(_opts) do
    quote do
      def handle_event("toggle", %{"label" => label_id}, socket) do
        active_label_ids =
          socket
          |> update_labels(label_id)
          |> get_active_label_ids()

        {
          :noreply,
          socket
          |> update_selected_labels(active_label_ids)
        }
      end

      defp get_active_label_ids(labels) do
        labels
        |> Enum.filter(& &1.active)
        |> Enum.map(& &1.id)
      end

      defp update_labels(socket, label_id_to_toggle) do
        socket
        |> all_labels()
        |> Enum.map(&toggle(&1, label_id_to_toggle))
      end

      defp toggle(label, label_id) when is_atom(label_id) do
        if label.id === label_id do
          %{label | active: !label.active}
        else
          label
        end
      end

      defp toggle(label, label_id), do: toggle(label, String.to_atom(label_id))
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center">
      <For each={{ {label, index} <- Enum.with_index(@labels) }}>
        <If condition={{ index>0 }}>
          <Spacing value="XS" direction="l" />
        </If>
        <div x-data="{ active: {{ label.active }} }"  >
          <div
            x-on:mousedown="active = !active"
            :class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
            class="cursor-pointer rounded-full px-6 py-3 text-label font-label select-none"
            :on-click="toggle"
            phx-value-label="{{ label.id }}"
            phx-target={{@target}}
          >
            {{ label.value }}
          </div>
        </div>
      </For>
    </div>
    """
  end
end
