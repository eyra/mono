defmodule Systems.Lab.DayEntryView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Selector

  def update(%{entry: entry}, socket) do
    {
      :ok,
      socket
      |> assign(entry: entry)
      |> update_timestamp()
      |> compose_child(:selector)
    }
  end

  @impl true
  def compose(:selector, %{entry: %{type: :break}}), do: nil

  @impl true
  def compose(:selector, %{entry: %{enabled?: enabled?}}) do
    %{
      module: Selector,
      params: %{
        items: [%{id: :id, active: enabled?}],
        type: :checkbox
      }
    }
  end

  defp update_timestamp(%{assigns: %{entry: %{type: :break}}} = socket), do: socket

  defp update_timestamp(%{assigns: %{entry: %{start_time: start_time}}} = socket) do
    timestamp =
      if start_time >= 0 and start_time <= 2400 do
        hour = (start_time / 100) |> trunc()
        minute = "#{rem(start_time, 100)}" |> String.pad_leading(2, "0")
        "#{hour}:#{minute}"
      else
        "--:--"
      end

    socket |> assign(timestamp: timestamp)
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_ids: active_item_ids},
        %{assigns: %{entry: entry}} = socket
      ) do
    enabled? = not Enum.empty?(active_item_ids)
    entry = %{entry | enabled?: enabled?}

    {
      :noreply,
      socket
      |> assign(entry: entry)
      |> send_event(:parent, "day_entry_updated", %{entry: entry})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @entry.type == :break do %>
        <div class="flex flex-row items-center h-6 w-full">
          <div class="h-1px w-full">
            <.line />
          </div>
        </div>
      <% else %>
        <div class="flex flex-row items-center h-12 w-full">
          <div class="w-10">
            <.child name={:selector} fabric={@fabric} />
          </div>
          <div class="w-12">
            <Text.body_large color={if @entry.enabled? do
              "text-grey1"
            else
              "text-grey2"
            end}>
              <%= @entry.bullet %>
            </Text.body_large>
          </div>
          <div class="w-16">
            <Text.body_medium color={if @entry.enabled? do
              "text-grey1"
            else
              "text-grey2"
            end}>
              <%= @timestamp %>
            </Text.body_medium>
          </div>
          <div class="flex-grow" />
          <div>
            <Text.body_medium>
              <%= if @entry.enabled? do %>
                <span><%= dngettext("link-lab", "1 seat", "%{count} seats", @entry.number_of_seats) %></span>
              <% else %>
                <span class="text-grey2"><%= dgettext("link-lab", "time.slot.item.available.label") %></span>
              <% end %>
            </Text.body_medium>
          </div>
          <div class="flex-grow" />
          <div class="w-32">
            <%= if @entry.number_of_reservations > 0 do %>
              <Text.body_medium align="text-right" color="text-warning">
                <%= dngettext("link-lab", "1 reservation", "%{count} reservations", @entry.number_of_reservations) %>
              </Text.body_medium>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
