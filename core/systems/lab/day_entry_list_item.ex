defmodule Systems.Lab.DayEntryListItem do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Text.{BodyMedium}
  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Line

  prop type, :atom, required: true
  prop data, :map
  prop target, :any

  defp timestamp(%{start_time: start_time}) do
    hour = start_time / 100 |> trunc()
    minute = "#{rem(start_time, 100)}" |> String.pad_leading(2, "0")

    "#{hour}:#{minute}"
  end
  defp timestamp(_), do: nil

  def render(assigns) do
    ~F"""
      <div>
        <div :if={@type == :break} class="w-full mb-3">
          <Line />
        </div>
        <div :if={@type == :time_slot} class="h-12 w-full">
          <div class="flex flex-row items-center gap-2">
            <Selector id={:"#{@data.start_time}"} items={[%{id: :id, active: @data.enabled}]} type={:checkbox} parent={@target}/>
            <div class="mt-2px w-full">
              <div class="flex flex-row w-full">
                <div class="w-24">
                  <BodyMedium color={if @data.enabled do "text-grey1" else "text-grey2" end}>{timestamp(@data)}</BodyMedium>
                </div>
                <BodyMedium>
                  <span :if={@data.enabled}>10 participants</span>
                  <span :if={not @data.enabled} class="text-grey2">Not scheduled</span>
                </BodyMedium>
              </div>
            </div>
          </div>
        </div>
      </div>
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
      <DayEntryListItem type={:time_slot} data={%{start_time: 900, enabled: true}} target={self()} />
      <DayEntryListItem type={:break} />
      <DayEntryListItem type={:time_slot} data={%{start_time: 1000, enabled: true}} target={self()} />
    </div>
    """
  end
end
