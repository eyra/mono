defmodule Systems.Lab.PublicPage do
  @moduledoc """
  The public lab screen.
  """
  use CoreWeb, :live_view

  alias Systems.Lab

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    tool = Lab.Public.get_tool!(id, [:time_slots])

    {:ok,
     socket
     |> assign(:tool, tool)
     |> assign(:reservation, Lab.Public.reservation_for_user(tool, user))}
  end

  @impl true
  def handle_event(
        "reserve-time-slot",
        %{"time-slot-id" => time_slot_id},
        %{assigns: %{current_user: user}} = socket
      ) do
    # FIXME: Add logic here to handle case when the time slot is in the past (show error message to the user)
    {:ok, reservation} =
      time_slot_id
      |> String.to_integer()
      |> Lab.Public.reserve_time_slot(user)

    {:noreply, socket |> assign(:reservation, reservation)}
  end

  @impl true
  def handle_event(
        "cancel-reservation",
        _params,
        %{assigns: %{current_user: user, tool: tool}} = socket
      ) do
    Lab.Public.cancel_reservation(tool, user)
    {:noreply, socket |> assign(:reservation, nil)}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  # data(reservation, :any, default: nil)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if @reservation do %>
        <div>
          You have made a reservation
          <button
            phx-click="cancel-reservation"
            data-confirm="Are you sure you want to cancel the reservation?"
          >Cancel</button>
        </div>
      <% end %>

      <table>
        <%= for slot <- @tool.time_slots do %>
          <tr>
            <td><%= slot.start_time %></td>
            <td><%= slot.location %></td>
            <td><%= slot.number_of_seats %></td>
            <td>
              <%= if is_nil(@reservation) || @reservation.time_slot_id != slot.id do %>
                <button
                  phx-click="reserve-time-slot"
                  phx-value-time-slot-id={slot.id}
                  data-confirm={not is_nil(@reservation) and "Are you sure you want to switch your reservation?"}
                >
                  Apply
                </button>
              <% end %>
            </td>
          </tr>
        <% end %>
      </table>
      </Area.content>
    </div>
    """
  end
end
