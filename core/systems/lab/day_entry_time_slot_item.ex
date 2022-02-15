defmodule Systems.Lab.DayEntryTimeSlotItem do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Text.{BodyLarge, BodyMedium}
  alias Frameworks.Pixel.Selector.Selector

  prop(enabled?, :boolean, default: true)
  prop(bullet, :string, required: true)
  prop(start_time, :number, required: true)
  prop(number_of_seats, :number, required: true)
  prop(number_of_reservations, :number, required: true)
  prop(target, :any)

  defp timestamp(start_time) when start_time >= 0 and start_time <= 2400 do
    hour = (start_time / 100) |> trunc()
    minute = "#{rem(start_time, 100)}" |> String.pad_leading(2, "0")

    "#{hour}:#{minute}"
  end

  defp timestamp(_), do: "--:--"

  def render(assigns) do
    ~F"""
      <div class="flex flex-row items-center h-12 w-full">
        <div class="w-10">
          <Selector id={@start_time} items={[%{id: :id, active: @enabled?}]} type={:checkbox} parent={@target}/>
        </div>
        <div class="w-12">
          <BodyLarge color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {@bullet}
          </BodyLarge>
        </div>
        <div class="w-16">
          <BodyMedium color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {timestamp(@start_time)}
          </BodyMedium>
        </div>
        <div class="flex-grow"></div>
        <div>
          <BodyMedium>
            <span :if={@enabled?}>{dngettext("link-lab", "1 seat", "%{count} seats", @number_of_seats)}</span>
            <span :if={not @enabled?} class="text-grey2">{dgettext("link-lab", "time.slot.item.available.label")}</span>
          </BodyMedium>
        </div>
        <div class="flex-grow"></div>
        <div class="w-32">
          <div :if={@number_of_reservations > 0}>
            <BodyMedium align="text-right" color="text-warning">
              {dngettext("link-lab", "1 reservation", "%{count} reservations", @number_of_reservations)}
            </BodyMedium>
          </div>
        </div>
      </div>
    """
  end
end

defmodule Systems.Lab.DayEntryTimeSlotItem.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.DayEntryTimeSlotItem,
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
    <div class="w-full">
      <DayEntryTimeSlotItem start_time={-900} enabled?={true} bullet="1." number_of_seats={1} number_of_reservations={1} target={self()} />
      <DayEntryTimeSlotItem start_time={-0} enabled?={true} bullet="2." number_of_seats={2} number_of_reservations={2} target={self()} />
      <DayEntryTimeSlotItem start_time={900} enabled?={true} bullet="3." number_of_seats={3} number_of_reservations={3} target={self()} />
      <DayEntryTimeSlotItem start_time={1000} enabled?={true} bullet="4." number_of_seats={4} number_of_reservations={0} target={self()} />
      <DayEntryTimeSlotItem start_time={2600} enabled?={true} bullet="5." number_of_seats={5} number_of_reservations={0} target={self()} />
      <DayEntryTimeSlotItem start_time={1100} enabled?={false} bullet="-" number_of_seats={6} number_of_reservations={2} target={self()} />
      <DayEntryTimeSlotItem start_time={1200} enabled?={false} bullet="-" number_of_seats={7} number_of_reservations={0} target={self()} />
    </div>
    """
  end
end
