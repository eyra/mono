defmodule Frameworks.Pixel.Selector.Selector do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  prop(items, :list, required: true)
  prop(parent, :any, required: true)
  prop(type, :atom, default: :label)
  prop(background, :atom, default: :light)
  prop(optional?, :boolean, default: true)
  prop(grid_options, :string, default: "")
  prop(opts, :string, default: "")

  prop(current_items, :list)

  defp grid_options(_, grid_options) when grid_options != "", do: grid_options
  defp grid_options(:radio, _), do: "flex flex-col gap-3"
  defp grid_options(:checkbox, _), do: "flex flex-row flex-wrap gap-x-8 gap-y-3 items-center"
  defp grid_options(_, _), do: "flex flex-row flex-wrap gap-3 items-center"

  defp multiselect?(:radio), do: false
  defp multiselect?(_), do: true

  def update(%{reset: new_items}, socket) do
    {
      :ok,
      socket
      |> assign(current_items: new_items)
    }
  end

  def update(
        %{
          id: id,
          items: items,
          parent: parent,
          type: type,
          background: background,
          optional?: optional?,
          grid_options: grid_options,
          opts: opts
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        items: items,
        current_items: items,
        parent: parent,
        type: type,
        background: background,
        optional?: optional?,
        grid_options: grid_options,
        opts: opts
      )
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
         %{assigns: %{type: type, parent: parent, current_items: current_items, id: selector_id}},
         active_item_ids
       ) do
    if multiselect?(type) do
      update_target(parent, %{
        selector_id: selector_id,
        active_item_ids: active_item_ids,
        current_items: current_items
      })
    else
      active_item_id = List.first(active_item_ids)

      update_target(parent, %{
        selector_id: selector_id,
        active_item_id: active_item_id,
        current_items: current_items
      })
    end
  end

  defp get_active_item_ids(%{assigns: %{current_items: items}}) do
    items
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.id)
  end

  defp active_count(items) do
    items
    |> Enum.filter(& &1.active)
    |> Enum.count()
  end

  defp update_items(%{assigns: %{current_items: items}} = socket, item_id_to_toggle) do
    items =
      items
      |> Enum.map(&toggle(socket, &1, item_id_to_toggle))

    socket |> assign(current_items: items)
  end

  defp toggle(%{assigns: %{items: items, type: type, optional?: optional?}}, item, item_id)
       when is_atom(item_id) do
    multiselect? = multiselect?(type)
    active_count = active_count(items)

    if is_same_id?(item.id, item_id) do
      if not item.active or optional? or (multiselect? and active_count > 1) do
        %{item | active: !item.active}
      else
        # prevent deselection
        item
      end
    else
      if multiselect? do
        item
      else
        %{item | active: false}
      end
    end
  end

  defp toggle(socket, item, item_id), do: toggle(socket, item, String.to_atom(item_id))

  defp is_same_id?(left, right) when is_number(left) and is_atom(right) do
    "#{left}" == Atom.to_string(right)
  end

  defp is_same_id?(left, right) when is_binary(left) and is_atom(right) do
    left == Atom.to_string(right)
  end

  defp is_same_id?(left, right) do
    left == right
  end

  defp item_component(:radio), do: Frameworks.Pixel.Selector.Radio
  defp item_component(:checkbox), do: Frameworks.Pixel.Selector.Checkbox
  defp item_component(_), do: Frameworks.Pixel.Selector.Label

  def render(assigns) do
    ~F"""
    <div class={"#{grid_options(@type, @grid_options)} #{@opts}"}>
      {#for {item, _} <- Enum.with_index(@current_items)}
        <div x-data={"{ active: #{item.active}, is_optional: #{@optional?} }"} >
          <div
            x-on:mousedown="if (is_optional) { active = !active }"
            class="cursor-pointer select-none"
            :on-click="toggle"
            phx-value-item={"#{item.id}"}
            phx-target={@myself}
          >
            <Surface.Components.Dynamic.Component
              module={item_component(@type)}
              item={item}
              multiselect?={ multiselect?(@type) }
              background={@background}
            />
          </div>
        </div>
      {/for}
    </div>
    """
  end
end
