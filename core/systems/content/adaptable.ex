defmodule Systems.Content.Adaptable do
  @moduledoc """
  Adaptable layout system that adjusts presentation based on item count.

  ## Layout Behavior

  | Item Count | Layout           | Navigation UI          | Add Button(s)                    |
  |------------|------------------|------------------------|----------------------------------|
  | 0          | Empty state      | None                   | Buttons for each creatable type  |
  | 1          | Direct display   | None                   | Single "+" if creatables exist   |
  | 2-5        | Tabbed           | Segmented control      | Single "+" to right of tabs      |
  | >5         | Grouped tabs     | Segmented by type      | Per-group "+" buttons            |

  ## Usage

  ```elixir
  alias Systems.Content.Adaptable

  items = [
    Adaptable.Item.new(:org_1, :organisation, "VU Amsterdam", element: element),
    Adaptable.Item.new(:org_2, :organisation, "TU Delft", element: element)
  ]

  creatables = [
    Adaptable.Creatable.new(:organisation, "Organisation", %{type: :send, event: "create"})
  ]

  <.adaptable_layout
    socket={@socket}
    items={items}
    creatables={creatables}
    tabbar_id="my_tabbar"
  />
  ```
  """

  defmodule Item do
    @moduledoc """
    An item to display in the adaptable layout.

    Fields:
    - `id` - Unique identifier (used as tab id)
    - `type` - For grouping when >5 items
    - `title` - Display name for tab
    - `element` - LiveNest.Element for rendering content
    - `child` - Alternative: Fabric child for rendering content
    """
    @enforce_keys [:id, :type, :title]
    defstruct [:id, :type, :title, :element, :child]

    def new(id, type, title, opts \\ []) do
      %__MODULE__{
        id: id,
        type: type,
        title: title,
        element: Keyword.get(opts, :element),
        child: Keyword.get(opts, :child)
      }
    end
  end

  defmodule Creatable do
    @moduledoc """
    A creatable type that can be added via the layout's add button.

    Fields:
    - `type` - Matches item type for grouping
    - `label` - Display label for button
    - `action` - Button action map (e.g., `%{type: :send, event: "create"}`)
    """
    @enforce_keys [:type, :label, :action]
    defstruct [:type, :label, :action]

    def new(type, label, action) do
      %__MODULE__{
        type: type,
        label: label,
        action: action
      }
    end
  end

  use CoreWeb, :html

  alias Frameworks.Pixel.Navigation
  alias Frameworks.Pixel.Tabbed
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  @threshold 5

  attr(:socket, :map, required: true)
  attr(:items, :list, required: true)
  attr(:creatables, :list, default: [])
  attr(:tabbar_id, :any, required: true)
  attr(:initial_item, :any, default: nil)
  attr(:empty_state, :map, default: nil)

  def layout(assigns) do
    assigns = assign(assigns, :layout_mode, determine_layout(assigns.items))

    ~H"""
    <%= case @layout_mode do %>
      <% :empty -> %>
        <.empty_layout empty_state={@empty_state} creatables={@creatables} />
      <% :single -> %>
        <.single_layout socket={@socket} item={hd(@items)} creatables={@creatables} />
      <% :individual_tabs -> %>
        <.individual_tabs_layout
          socket={@socket}
          items={@items}
          creatables={@creatables}
          tabbar_id={@tabbar_id}
          initial_item={@initial_item}
        />
      <% :grouped_tabs -> %>
        <.grouped_tabs_layout
          socket={@socket}
          items={@items}
          creatables={@creatables}
          tabbar_id={@tabbar_id}
          initial_item={@initial_item}
        />
    <% end %>
    """
  end

  defp determine_layout(items) do
    case length(items) do
      0 -> :empty
      1 -> :single
      n when n <= @threshold -> :individual_tabs
      _ -> :grouped_tabs
    end
  end

  # Empty Layout - shows empty state with action buttons from creatables
  attr(:empty_state, :map, default: nil)
  attr(:creatables, :list, default: [])

  defp empty_layout(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-20">
      <%= if @empty_state do %>
        <Text.title2>{@empty_state.title}</Text.title2>
        <div class="mt-2">
          <Text.body_large color="text-grey2">{@empty_state.description}</Text.body_large>
        </div>
      <% end %>
      <%= if Enum.any?(@creatables) do %>
        <div class="flex flex-row gap-4 mt-8">
          <%= for creatable <- @creatables do %>
            <Button.dynamic {creatable_to_button(creatable)} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Single Layout - direct display without tabbar
  attr(:socket, :map, required: true)
  attr(:item, :map, required: true)
  attr(:creatables, :list, default: [])

  defp single_layout(assigns) do
    ~H"""
    <div>
      <.item_content socket={@socket} item={@item} />
    </div>
    """
  end

  # Individual Tabs Layout - segmented control for 2-5 items
  attr(:socket, :map, required: true)
  attr(:items, :list, required: true)
  attr(:creatables, :list, default: [])
  attr(:tabbar_id, :any, required: true)
  attr(:initial_item, :any, default: nil)

  defp individual_tabs_layout(assigns) do
    tabs = items_to_tabs(assigns.items)
    initial_tab = assigns.initial_item || hd(assigns.items).id

    assigns =
      assigns
      |> assign(:tabs, tabs)
      |> assign(:initial_tab, initial_tab)

    ~H"""
    <Navigation.tabbar>
      <div class="flex flex-row items-center gap-4">
        <Tabbed.bar
          id={@tabbar_id}
          tabs={@tabs}
          initial_tab={@initial_tab}
          size={:wide}
          type={:segmented}
          preserve_tab_in_url={true}
        />
        <%= if Enum.any?(@creatables) do %>
          <.add_button creatables={@creatables} />
        <% end %>
      </div>
    </Navigation.tabbar>
    <Tabbed.content socket={@socket} bar_id={@tabbar_id} tabs={@tabs} />
    """
  end

  # Grouped Tabs Layout - grouped by type for >5 items
  attr(:socket, :map, required: true)
  attr(:items, :list, required: true)
  attr(:creatables, :list, default: [])
  attr(:tabbar_id, :any, required: true)
  attr(:initial_item, :any, default: nil)

  defp grouped_tabs_layout(assigns) do
    groups = group_items_by_type(assigns.items)
    group_tabs = build_group_tabs(groups, assigns.creatables)
    initial_group = determine_initial_group(assigns.initial_item, groups)

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:group_tabs, group_tabs)
      |> assign(:initial_group, initial_group)

    ~H"""
    <Navigation.tabbar>
      <Tabbed.bar
        id={@tabbar_id}
        tabs={@group_tabs}
        initial_tab={@initial_group}
        size={:wide}
        type={:segmented}
        preserve_tab_in_url={true}
      />
    </Navigation.tabbar>
    <div id={"#{@tabbar_id}-tab_content"} phx-hook="TabContent">
      <%= for {group_type, group_items} <- @groups do %>
        <div
          id={"#{@tabbar_id}-tab_panel_#{group_type}"}
          data-tab-id={group_type}
          class="tab-panel hidden"
        >
          <.group_content
            socket={@socket}
            group_type={group_type}
            items={group_items}
            creatables={filter_creatables(@creatables, group_type)}
            tabbar_id={"#{@tabbar_id}_#{group_type}"}
          />
        </div>
      <% end %>
    </div>
    """
  end

  # Group content - shows items within a group with optional add button
  attr(:socket, :map, required: true)
  attr(:group_type, :atom, required: true)
  attr(:items, :list, required: true)
  attr(:creatables, :list, default: [])
  attr(:tabbar_id, :any, required: true)

  defp group_content(assigns) do
    tabs = items_to_tabs(assigns.items)
    initial_tab = hd(assigns.items).id

    assigns =
      assigns
      |> assign(:tabs, tabs)
      |> assign(:initial_tab, initial_tab)

    ~H"""
    <div class="mt-6">
      <div class="flex flex-row items-center gap-4 mb-4">
        <Tabbed.bar
          id={@tabbar_id}
          tabs={@tabs}
          initial_tab={@initial_tab}
          size={:wide}
          type={:segmented}
        />
        <%= if Enum.any?(@creatables) do %>
          <.add_button creatables={@creatables} />
        <% end %>
      </div>
      <Tabbed.content socket={@socket} bar_id={@tabbar_id} tabs={@tabs} />
    </div>
    """
  end

  # Render individual item content
  attr(:socket, :map, required: true)
  attr(:item, :map, required: true)

  defp item_content(assigns) do
    ~H"""
    <%= if @item.element do %>
      <LiveNest.HTML.element socket={@socket} {Map.from_struct(@item.element)} />
    <% end %>
    <%= if @item.child do %>
      <.live_component {Map.from_struct(@item.child.ref)} {@item.child.params} />
    <% end %>
    """
  end

  # Add button component
  attr(:creatables, :list, required: true)

  defp add_button(assigns) do
    button =
      case assigns.creatables do
        [single] -> creatable_to_button(single, :icon_only)
        multiple -> creatable_to_dropdown(multiple)
      end

    assigns = assign(assigns, :button, button)

    ~H"""
    <Button.dynamic {@button} />
    """
  end

  # Helper functions

  defp items_to_tabs(items) do
    Enum.map(items, fn item ->
      %{
        id: item.id,
        title: item.title,
        element: item.element,
        child: item.child
      }
    end)
  end

  defp group_items_by_type(items) do
    items
    |> Enum.group_by(& &1.type)
    |> Enum.sort_by(fn {type, _items} -> type end)
  end

  defp build_group_tabs(groups, _creatables) do
    Enum.map(groups, fn {type, items} ->
      %{
        id: type,
        title: "#{humanize_type(type)} (#{length(items)})"
      }
    end)
  end

  defp determine_initial_group(nil, [{first_type, _} | _]), do: first_type

  defp determine_initial_group(initial_item, groups) do
    Enum.find_value(groups, fn {type, items} ->
      if Enum.any?(items, &(&1.id == initial_item)), do: type
    end) || elem(hd(groups), 0)
  end

  defp filter_creatables(creatables, group_type) do
    Enum.filter(creatables, &(&1.type == group_type))
  end

  defp creatable_to_button(creatable, style \\ :primary) do
    face =
      case style do
        :icon_only ->
          %{type: :icon, icon: :add}

        :primary ->
          %{type: :primary, label: creatable.label, icon: :add}
      end

    %{
      action: creatable.action,
      face: face
    }
  end

  defp creatable_to_dropdown(creatables) do
    items =
      Enum.map(creatables, fn creatable ->
        %{
          label: creatable.label,
          action: creatable.action
        }
      end)

    %{
      action: %{type: :dropdown, items: items},
      face: %{type: :icon, icon: :add}
    }
  end

  defp humanize_type(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
