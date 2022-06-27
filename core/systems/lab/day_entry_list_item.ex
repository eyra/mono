defmodule Systems.Lab.DayEntryListItem do
  use CoreWeb.UI.Component

  alias Systems.Lab.{DayEntryBreakItem, DayEntryTimeSlotItem}

  prop(entry, :map, required: true)

  defp module(%{type: :time_slot}), do: DayEntryTimeSlotItem
  defp module(%{type: :break}), do: DayEntryBreakItem

  defp props(entry), do: Map.delete(entry, :type)

  def render(assigns) do
    ~F"""
    <Dynamic.Component module={module(@entry)} {...props(@entry)} />
    """
  end
end

defmodule Systems.Lab.DayEntryListItem.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.DayEntryListItem,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Day entry list item",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  def handle_info(%{active_item_id: nil, selector_id: selector_id}, socket) do
    IO.puts("Disabled #{selector_id}")
    {:noreply, socket}
  end

  def handle_info(%{active_item_id: _active_item_id, selector_id: selector_id}, socket) do
    IO.puts("Enabled #{selector_id}")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col">
      <DayEntryListItem entry={%{
        type: :time_slot,
        start_time: 900,
        enabled?: true,
        bullet: "1.",
        number_of_seats: 1,
        number_of_reservations: 1,
        target: self()
      }} />
      <DayEntryListItem entry={%{type: :break}} />
      <DayEntryListItem entry={%{
        type: :time_slot,
        start_time: 1000,
        enabled?: true,
        bullet: "2.",
        number_of_seats: 1,
        number_of_reservations: 1,
        target: self()
      }} />
    </div>
    """
  end
end
