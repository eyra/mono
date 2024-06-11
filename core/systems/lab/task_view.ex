defmodule Systems.Lab.TaskView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Navigation, only: [button_bar: 1]
  alias Frameworks.Utility.LiveCommand
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.DropdownSelector

  alias Systems.Lab

  # Realtime updates
  @impl true
  def update(%{model: new_model}, %{assigns: %{lock_ui: true}} = socket) do
    {:ok, socket |> assign(new_model: new_model)}
  end

  @impl true
  def update(
        %{
          model: %{
            lab_tool: lab_tool,
            status: status,
            actions: actions,
            reservation: reservation
          }
        },
        socket
      ) do
    selected_timeslot = Map.get(socket.assigns, :selected_timeslot, nil)

    {
      :ok,
      socket
      |> assign(
        lab_tool: lab_tool,
        status: status,
        actions: actions,
        reservation: reservation,
        selected_timeslot: selected_timeslot
      )
      |> update_timeslots()
      |> update_options()
      |> compose_child(:timeslot_selector)
    }
  end

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          public_id: public_id,
          lab_tool: lab_tool,
          status: status,
          actions: actions,
          reservation: reservation,
          user: user
        },
        socket
      ) do
    selected_timeslot = Map.get(socket.assigns, :selected_timeslot, nil)

    {
      :ok,
      socket
      |> assign(
        id: id,
        public_id: public_id,
        lab_tool: lab_tool,
        status: status,
        actions: actions,
        reservation: reservation,
        user: user,
        lock_ui: false,
        selected_timeslot: selected_timeslot
      )
      |> update_timeslots()
      |> update_options()
      |> compose_child(:timeslot_selector)
    }
  end

  @impl true
  def compose(:timeslot_selector, %{options: options, selected_timeslot: nil}) do
    %{
      module: DropdownSelector,
      params: %{
        options: options,
        selected_option_index: nil
      }
    }
  end

  def compose(:timeslot_selector, %{
        options: options,
        selected_timeslot: %{id: selected_timeslot_id}
      }) do
    selected_option_index = Enum.find_index(options, &(&1.id == selected_timeslot_id))

    %{
      module: DropdownSelector,
      params: %{
        options: options,
        selected_option_index: selected_option_index
      }
    }
  end

  # Updating

  defp update_options(%{assigns: %{timeslots: timeslots}} = socket) do
    options = Enum.map(timeslots, &to_option(&1))
    socket |> assign(options: options)
  end

  defp update_timeslots(%{assigns: %{lab_tool: %{id: id}}} = socket) do
    timeslots = Lab.Public.get_available_time_slots(id)
    socket |> assign(timeslots: timeslots)
  end

  defp to_option(%Lab.TimeSlotModel{id: id} = time_slot) do
    date = date(time_slot)
    time = time(time_slot)
    location = location(time_slot)

    %{
      id: id,
      value: "#{date}  |  #{time}  |  #{location}" |> Macro.camelize()
    }
  end

  defp handle_delayed_update(
         %{assigns: %{new_model: %{lab_tool: lab_tool, reservation: reservation}}} = socket
       ) do
    socket
    |> assign(
      lab_tool: lab_tool,
      reservation: reservation,
      new_model: nil
    )
    |> update_timeslots()
    |> update_child(:timeslot_selector)
  end

  defp handle_delayed_update(socket), do: socket

  defp date(%Lab.TimeSlotModel{start_time: start_time}) do
    start_time
    |> CoreWeb.UI.Timestamp.to_date()
    |> CoreWeb.UI.Timestamp.humanize_date()
  end

  defp time(%Lab.TimeSlotModel{start_time: start_time}) do
    start_time
    |> CoreWeb.UI.Timestamp.humanize_time()
  end

  defp location(%Lab.TimeSlotModel{location: location}), do: location

  defp time_slot(%{time_slot_id: time_slot_id}) do
    Lab.Public.get_time_slot(time_slot_id)
  end

  defp id_text(public_id) do
    label = dgettext("link-lab", "inquiry.checkin.label")
    "🆔  #{label}  #{public_id}"
  end

  # Actions

  defp action_buttons(%{actions: actions, myself: target}) do
    LiveCommand.action_buttons(actions, target)
  end

  @impl true
  def handle_event("dropdown_toggle", %{show_options?: show_options?}, socket) do
    {
      :noreply,
      socket
      |> assign(lock_ui: show_options?)
      |> handle_delayed_update()
    }
  end

  @impl true
  def handle_event("dropdown_reset", _, socket) do
    {
      :noreply,
      socket
      |> assign(
        selected_timeslot: nil,
        lock_ui: false
      )
      |> handle_delayed_update()
    }
  end

  @impl true
  def handle_event(
        "dropdown_selected",
        %{option: %{id: id}},
        %{assigns: %{timeslots: timeslots}} = socket
      ) do
    selected_timeslot = timeslots |> Enum.find(&(&1.id == id))

    {
      :noreply,
      socket
      |> assign(
        selected_timeslot: selected_timeslot,
        lock_ui: false
      )
      |> handle_delayed_update()
    }
  end

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, LiveCommand.execute(event, socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @reservation do %>
        <Text.title3><%= dgettext("link-lab", "reservation.title") %></Text.title3>
        <.spacing value="M" />
        <div class="flex flex-col sm:flex-row gap-x-4 gap-y-3">
          <Text.body><span class="whitespace-pre-wrap">🗓 <%= date(time_slot(@reservation)) %></span></Text.body>
          <Text.body><span class="whitespace-pre-wrap">🕙 <%= time(time_slot(@reservation)) %></span></Text.body>
          <Text.body><span class="whitespace-pre-wrap">📍 <%= location(time_slot(@reservation)) %></span></Text.body>
        </div>
        <.spacing value="XXS" />
        <Text.body><span class="whitespace-pre-wrap"><%= id_text(@public_id) %></span></Text.body>
        <.spacing value="S" />
      <% else %>
        <%= if @status == :pending do %>
          <Text.title3><%= dgettext("link-lab", "no.reservation.title") %></Text.title3>
          <.spacing value="M" />
          <Text.title6><%= dgettext("link-lab", "timeslot.selector.label") %></Text.title6>
          <.spacing value="XXS" />
          <.child name={:timeslot_selector} fabric={@fabric} />
        <% end %>
      <% end %>
      <Margin.y id={:button_bar_top} />
      <.button_bar buttons={action_buttons(assigns)} />
    </div>
    """
  end
end
