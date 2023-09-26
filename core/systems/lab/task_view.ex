defmodule Systems.Lab.TaskView do
  use CoreWeb, :live_component

  import CoreWeb.UI.Navigation, only: [button_bar: 1]
  alias Frameworks.Utility.LiveCommand
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Dropdown

  alias Systems.{
    Lab
  }

  # Selector updates
  @impl true
  def update(%{selector: :toggle, show_options?: show_options?}, socket) do
    {
      :ok,
      socket
      |> assign(lock_ui: show_options?)
      |> handle_delayed_update()
    }
  end

  @impl true
  def update(%{selector: :reset}, socket) do
    {
      :ok,
      socket
      |> assign(
        selected_time_slot: nil,
        lock_ui: false
      )
      |> handle_delayed_update()
    }
  end

  @impl true
  def update(
        %{selector: :selected, option: %{id: id}},
        %{assigns: %{time_slots: time_slots}} = socket
      ) do
    selected_time_slot = time_slots |> Enum.find(&(&1.id == id))

    {
      :ok,
      socket
      |> assign(
        selected_time_slot: selected_time_slot,
        lock_ui: false
      )
      |> handle_delayed_update()
    }
  end

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
    {
      :ok,
      socket
      |> assign(
        lab_tool: lab_tool,
        status: status,
        actions: actions,
        reservation: reservation
      )
      |> update_time_slots()
      |> update_selector()
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
        lock_ui: false
      )
      |> update_time_slots()
      |> init_selector()
    }
  end

  # Updating

  defp handle_delayed_update(
         %{assigns: %{new_model: %{lab_tool: lab_tool, reservation: reservation}}} = socket
       ) do
    socket
    |> assign(
      lab_tool: lab_tool,
      reservation: reservation,
      new_model: nil
    )
    |> update_time_slots()
    |> update_selector()
  end

  defp handle_delayed_update(socket), do: socket

  defp update_time_slots(%{assigns: %{lab_tool: %{id: id}}} = socket) do
    time_slots = Lab.Public.get_available_time_slots(id)
    socket |> assign(time_slots: time_slots)
  end

  defp init_selector(%{assigns: %{id: id, time_slots: time_slots}} = socket) do
    options = time_slots |> Enum.map(&to_option(&1))

    selector = %{
      id: :dropdown_selector,
      selected_option_index: nil,
      options: options,
      parent: %{type: __MODULE__, id: id}
    }

    socket |> assign(selector: selector, selected_time_slot: nil)
  end

  defp update_selector(%{assigns: %{time_slots: time_slots}} = socket) do
    options = time_slots |> Enum.map(&to_option(&1))
    send_update(Dropdown.Selector, id: :dropdown_selector, model: %{options: options})
    socket
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

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, LiveCommand.execute(event, socket)}
  end

  defp action_buttons(%{actions: actions, myself: target}) do
    LiveCommand.action_buttons(actions, target)
  end

  # data(selector, :map)
  # data(selected_time_slot, :map)

  attr(:lab_tool, :map, required: true)
  attr(:public_id, :any, required: true)
  attr(:status, :any, required: true)
  attr(:reservation, :any, required: true)
  attr(:actions, :list, required: true)
  attr(:user, :map, required: true)

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
          <.live_component module={Dropdown.Selector} {@selector} />
        <% end %>
      <% end %>
      <Margin.y id={:button_bar_top} />
      <.button_bar buttons={action_buttons(assigns)} />
    </div>
    """
  end
end
