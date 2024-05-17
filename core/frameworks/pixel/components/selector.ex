defmodule Frameworks.Pixel.Selector do
  @moduledoc false
  use CoreWeb, :live_component

  import CoreWeb.LiveDefaults

  @defaults [
    background: :light,
    optional?: true,
    grid_options: "",
    opts: ""
  ]

  defp grid_options(_, grid_options) when grid_options != "", do: grid_options
  defp grid_options(:radio, _), do: "flex flex-col gap-3"
  defp grid_options(:checkbox, _), do: "flex flex-row flex-wrap gap-x-8 gap-y-3 items-center"

  defp grid_options(:segmented, _),
    do: "flex flex-row flex-wrap gap-0 items-center rounded-full overflow-hidden"

  defp grid_options(_, _), do: "flex flex-row flex-wrap gap-3 items-center"

  defp multiselect?(:radio), do: false
  defp multiselect?(:segmented), do: false
  defp multiselect?(_), do: true

  @impl true
  def update(%{reset: new_items}, socket) do
    {
      :ok,
      socket
      |> assign(current_items: new_items)
    }
  end

  @impl true
  def update(%{items: new_items}, %{assigns: %{items: _items}} = socket) do
    {
      :ok,
      socket
      |> assign(current_items: new_items)
    }
  end

  @impl true
  def update(
        %{
          id: id,
          items: items,
          type: type
        } = props,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        items: items,
        current_items: items,
        type: type
      )
      |> update_defaults(props, @defaults)
    }
  end

  @impl true
  def handle_event("toggle", %{"item" => item_id}, socket) do
    socket =
      socket
      |> update_items(item_id)

    active_item_ids =
      socket
      |> get_active_item_ids()

    {:noreply, socket |> send_to_parent(active_item_ids)}
  end

  defp send_to_parent(
         %{assigns: %{type: type, current_items: current_items, id: selector_id}} = socket,
         active_item_ids
       ) do
    if multiselect?(type) do
      socket
      |> send_event(:parent, "active_item_ids", %{
        selector_id: selector_id,
        active_item_ids: active_item_ids,
        current_items: current_items
      })
    else
      active_item_id = List.first(active_item_ids)

      socket
      |> send_event(:parent, "active_item_id", %{
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
    |> Enum.count(& &1.active)
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

    if same_id?(item.id, item_id) do
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

  defp same_id?(left, right) when is_number(left) and is_atom(right) do
    "#{left}" == Atom.to_string(right)
  end

  defp same_id?(left, right) when is_binary(left) and is_atom(right) do
    left == Atom.to_string(right)
  end

  defp same_id?(left, right) do
    left == right
  end

  defp item_component(:radio), do: &Frameworks.Pixel.Selector.Item.radio/1
  defp item_component(:checkbox), do: &Frameworks.Pixel.Selector.Item.checkbox/1
  defp item_component(:segmented), do: &Frameworks.Pixel.Selector.Item.segment/1
  defp item_component(_), do: &Frameworks.Pixel.Selector.Item.label/1

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"#{grid_options(@type, @grid_options)} #{@opts}"}>
      <%= for {item, _} <- Enum.with_index(@current_items) do %>
        <div x-data={"{ active: #{item.active}, is_optional: #{@optional?} }"}>
          <div
            x-on:mousedown="if (is_optional) { active = !active }"
            class="cursor-pointer select-none"
            phx-click="toggle"
            phx-value-item={"#{item.id}"}
            phx-target={@myself}
          >
            <.function_component
              function={item_component(@type)}
              props={%{
                item: item,
                multiselect?: multiselect?(@type),
                background: @background
              }}
            />
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Selector.Item do
  @moduledoc false
  use CoreWeb, :pixel

  attr(:item, :map, required: true)
  attr(:multiselect?, :boolean, default: true)
  attr(:background, :atom, default: :light)

  def radio(%{item: %{value: value}, background: background} = assigns) do
    label_color =
      if background == :dark do
        "text-white"
      else
        "text-grey1"
      end

    active_icon =
      if background == :dark do
        "radio_active_tertiary"
      else
        "radio_active"
      end

    inactive_icon = "radio"

    assigns =
      assign(assigns, %{
        value: value,
        label_color: label_color,
        active_icon: active_icon,
        inactive_icon: inactive_icon
      })

    ~H"""
    <button class="flex flex-row gap-3 items-center">
      <div>
        <img
          x-show="active"
          src={~p"/images/icons/#{"#{@active_icon}.svg"}"}
          alt={"#{@value} is selected"}
        />
        <img
          x-show="!active"
          src={~p"/images/icons/#{"#{@inactive_icon}.svg"}"}
          alt={"Select #{@value}"}
        />
      </div>
      <div class={"#{@label_color} text-label font-label select-none mt-1"}>
        <%= @value %>
      </div>
    </button>
    """
  end

  attr(:item, :map, required: true)
  attr(:multiselect?, :boolean, default: true)
  attr(:background, :atom, default: :light)

  def label(assigns) do
    ~H"""
    <div
      x-bind:class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
      class="rounded-full px-6 py-3 text-label font-label select-none"
    >
      <%= @item.value %>
    </div>
    """
  end

  attr(:item, :map, required: true)
  attr(:multiselect?, :boolean, default: true)
  attr(:background, :atom, default: :light)

  def segment(assigns) do
    ~H"""
    <div
      x-bind:class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
      class="px-6 py-3 text-label font-label select-none"
    >
      <%= @item.value %>
    </div>
    """
  end

  attr(:item, :map, required: true)
  attr(:multiselect?, :boolean, default: true)
  attr(:background, :atom, default: :light)

  def checkbox(%{item: %{value: value} = item, multiselect?: multiselect?} = assigns) do
    accent = Map.get(item, :accent)

    font =
      if multiselect? do
        "text-label font-label"
      else
        "text-title6 font-title6"
      end

    text_color =
      if accent == :tertiary do
        "text-grey6"
      else
        "text-grey1"
      end

    active_icon =
      if accent == :tertiary do
        "check_active_tertiary"
      else
        "check_active"
      end

    inactive_icon =
      if accent == :tertiary do
        "check_tertiary"
      else
        "check"
      end

    assigns =
      assign(assigns, %{
        value: value,
        font: font,
        text_color: text_color,
        active_icon: active_icon,
        inactive_icon: inactive_icon
      })

    ~H"""
    <div class="flex flex-row gap-3 items-center">
      <div class="flex-shrink-0">
        <img
          x-show="active"
          src={~p"/images/icons/#{"#{@active_icon}.svg"}"}
          alt={"#{@value} is selected"}
        />
        <img
          x-show="!active"
          src={~p"/images/icons/#{"#{@inactive_icon}.svg"}"}
          alt={"Select #{@value}"}
        />
      </div>
      <div class={" select-none mt-1 #{@font} #{@text_color} leading-5"}>
        <%= @value %>
      </div>
    </div>
    """
  end
end
