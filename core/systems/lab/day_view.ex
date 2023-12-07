defmodule Systems.Lab.DayView do
  use CoreWeb, :live_component

  require Logger

  alias CoreWeb.UI.Timestamp

  import Frameworks.Pixel.Line
  import Frameworks.Pixel.Form

  alias Systems.{
    Lab
  }

  import CoreWeb.Gettext

  @impl true
  def update(%{id: id, day_model: day_model, target: target}, socket) do
    changeset =
      day_model
      |> Lab.DayModel.changeset(:init, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        target: target,
        og_day_model: day_model,
        day_model: day_model,
        changeset: changeset
      )
      |> update_ui()
    }
  end

  @impl true
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{day_model: %{entries: entries} = day_model}} = socket
      ) do
    start_time = selector_id
    enabled? = not Enum.empty?(active_item_ids)

    entries =
      entries
      |> update_changed_entry(start_time, enabled?)

    {
      :ok,
      socket
      |> assign(day_model: %{day_model | entries: entries})
      |> update_ui()
    }
  end

  @impl true
  def update(_params, socket) do
    {
      :ok,
      socket
    }
  end

  defp update_changed_entry(entries, start_time, enabled?) when is_list(entries) do
    case entries |> Enum.find_index(&has_start_time(&1, start_time)) do
      nil ->
        entries

      index ->
        entry = Enum.at(entries, index)

        entries
        |> List.replace_at(
          index,
          %{entry | enabled?: enabled?}
        )
    end
  end

  defp update_entries(
         %{
           assigns: %{
             id: id,
             day_model: %{number_of_seats: number_of_seats, entries: entries} = day_model
           }
         } = socket
       )
       when is_list(entries) do
    enabled_timeslots = Enum.filter(entries, &(&1.type == :time_slot and &1.enabled?))

    entries =
      entries
      |> Enum.map(&update_entry(:timeslot_bullet, &1, enabled_timeslots))
      |> Enum.map(&update_entry(:timeslot_number_of_seats, &1, number_of_seats))
      |> Enum.map(&update_entry(:timeslot_target, &1, id))

    socket
    |> assign(day_model: %{day_model | entries: entries})
  end

  defp find_index(timeslot, timeslots) do
    timeslots
    |> Enum.find_index(&(&1.start_time == timeslot.start_time))
  end

  defp has_start_time(%{start_time: og_start_time}, start_time), do: og_start_time == start_time
  defp has_start_time(_entry, _start_time), do: false

  defp update_ui(socket) do
    socket
    |> update_title()
    |> update_entries()
    |> update_byline()
  end

  defp update_title(%{assigns: %{day_model: %{date: date}}} = socket) do
    assign(socket, title: Timestamp.humanize_date(date))
  end

  defp update_entry(:timeslot_bullet, %{type: :time_slot} = timeslot, enabled_timeslots) do
    bullet =
      if timeslot.enabled? do
        index = find_index(timeslot, enabled_timeslots)
        "#{index + 1}."
      else
        "-"
      end

    Map.put(timeslot, :bullet, bullet)
  end

  defp update_entry(
         :timeslot_number_of_seats,
         %{type: :time_slot, number_of_reservations: number_of_reservations} = timeslot,
         number_of_seats
       ) do
    if number_of_seats >= number_of_reservations do
      Map.put(timeslot, :number_of_seats, number_of_seats)
    else
      Map.put(timeslot, :number_of_seats, number_of_reservations)
    end
  end

  defp update_entry(:timeslot_target, %{type: :time_slot} = timeslot, id) do
    Map.put(timeslot, :target, %{type: __MODULE__, id: id})
  end

  defp update_entry(_, entry, _timeslots), do: entry

  defp update_byline(socket) do
    time_slots =
      dngettext("link-lab", "1 time slot", "%{count} time slots", number_of_time_slots(socket))

    seats = dngettext("link-lab", "1 seat", "%{count} seats", number_of_seats(socket))

    byline = dgettext("link-lab", "day.schedule.byline", time_slots: time_slots, seats: seats)
    assign(socket, byline: byline)
  end

  defp enabled_time_slots(%{assigns: %{day_model: %{entries: entries}}}) do
    entries |> Enum.filter(&(&1.type == :time_slot and &1.enabled?))
  end

  defp number_of_time_slots(socket) do
    socket
    |> enabled_time_slots()
    |> Enum.count()
  end

  defp number_of_seats(socket) do
    socket
    |> enabled_time_slots()
    |> Enum.reduce(0, &(&2 + &1.number_of_seats))
  end

  defp validate_unused_date(
         %{
           assigns: %{
             og_day_model: %{date: og_date, location: og_location},
             day_model: %{action: action, tool_id: tool_id, date: date, location: location}
           }
         } = socket
       ) do
    time_slots =
      tool_id
      |> Lab.Public.get_time_slots()
      |> Enum.filter(
        &(&1.location == location and CoreWeb.UI.Timestamp.to_date(&1.start_time) == date)
      )

    error =
      if Enum.empty?(time_slots) or
           (action == :edit and og_date == date and og_location == location) do
        nil
      else
        dgettext("link-lab", "date.location.error")
      end

    socket |> assign(error: error)
  end

  @impl true
  def handle_event(
        "update",
        %{"day_model" => new_day_model},
        %{assigns: %{day_model: day_model}} = socket
      ) do
    changeset = Lab.DayModel.changeset(day_model, :submit, new_day_model)

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, day_model} ->
          socket
          |> assign(changeset: changeset, day_model: day_model)
          |> validate_unused_date()

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket |> update_ui()}
  end

  @impl true
  def handle_event(
        "submit",
        _,
        %{
          assigns: %{
            error: nil,
            changeset: changeset,
            og_day_model: og_day_model,
            day_model: day_model,
            target: target
          }
        } = socket
      ) do
    if changeset.valid? do
      update_target(target, %{day_view: :submit, og_day_model: og_day_model, day_model: day_model})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{target: target}} = socket) do
    update_target(target, %{day_view: :hide})
    {:noreply, socket}
  end

  defp buttons(%{myself: myself}) do
    [
      %{
        action: %{type: :submit},
        face: %{type: :primary, label: dgettext("link-lab", "day.schedule.submit.button")}
      },
      %{
        action: %{type: :send, event: "cancel", target: myself},
        face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
      }
    ]
  end

  # data(date, :date)
  # data(title, :string)
  # data(byline, :string)
  # data(entity, :map)
  # data(changeset, :map)
  # data(error, :any, default: nil)

  attr(:day_model, :map, default: nil)
  attr(:target, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8 w-popup-md bg-white shadow-floating rounded">
      <div>
        <%= if @error do %>
          <div class="text-button font-button text-warning leading-6">
            <%= @error %>
          </div>
          <.spacing value="XS" />
        <% end %>

        <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
          <%= @title %>
        </div>
        <.spacing value="XS" />
        <.form id="day_view" :let={form} for={@changeset} phx-change="update" phx-submit="submit" phx-target={@myself} >
          <.wrap>
            <%= if @day_model.date_editable? do %>
            <.date_input form={form}
              field={:date}
              label_text={dgettext("link-lab", "day.schedule.date.label")}
            />
            <% end %>
          </.wrap>
          <div class="flex flex-row gap-8">
            <div class="flex-grow">
              <.text_input form={form}
                field={:location}
                label_text={dgettext("link-lab", "day.schedule.location.label")}
                debounce="0"
              />
            </div>
            <div class="w-24">
              <.number_input form={form}
                field={:number_of_seats}
                label_text={dgettext("link-lab", "day.schedule.seats.label")}
                debounce="0"
              />
            </div>
          </div>
          <Text.sub_head color="text-grey2">
            <%= @byline %>
          </Text.sub_head>
          <.spacing value="M" />
          <.line />
          <div class="h-lab-day-popup-list overflow-y-scroll overscroll-contain">
            <div class="h-2" />
            <div class="w-full">
              <%= for entry <- @day_model.entries do %>
                <div>
                  <Lab.DayEntry.time_slot_item {entry} />
                </div>
              <% end %>
            </div>
          </div>
          <.line />
          <.spacing value="M" />
          <div class="flex flex-row gap-4">
            <%= for button <- buttons(assigns) do %>
              <Button.dynamic {button} />
            <% end %>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
