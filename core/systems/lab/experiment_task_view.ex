defmodule Systems.Lab.ExperimentTaskView do
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.ButtonBar
  alias Frameworks.Utility.LiveCommand
  alias Frameworks.Pixel.Text.{Title3, Title6, BodyLarge}
  alias Frameworks.Pixel.Dropdown

  alias Systems.{
    Lab
  }

  prop(lab_tool, :map, required: true)
  prop(status, :any, required: true)
  prop(reservation, :any, required: true)
  prop(actions, :list, required: true)
  prop(user, :map, required: true)

  data(selector, :map)
  data(selected_time_slot, :map)

  # Selector updates
  def update(%{selector: :toggle, show_options?: show_options?}, socket) do
    {
      :ok,
      socket
      |> assign(lock_ui: show_options?)
      |> handle_delayed_update()
    }
  end

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
  def update(%{model: new_model}, %{assigns: %{lock_ui: true}} = socket) do
    {:ok, socket |> assign(new_model: new_model)}
  end

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
  def update(
        %{
          id: id,
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
    time_slots = Lab.Context.get_available_time_slots(id)
    socket |> assign(time_slots: time_slots)
  end

  defp init_selector(%{assigns: %{id: id, time_slots: time_slots}} = socket) do
    options = time_slots |> Enum.map(&to_option(&1))

    selector = %{
      id: :dropdown_selector,
      field: :dropdown_selector,
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

  defp to_option(%Lab.TimeSlotModel{id: id, start_time: start_time, location: location}) do
    date =
      start_time
      |> CoreWeb.UI.Timestamp.to_date()
      |> CoreWeb.UI.Timestamp.humanize_date()

    time =
      start_time
      |> CoreWeb.UI.Timestamp.humanize_time()

    %{
      id: id,
      label: "#{date}  |  #{time}  |  #{location}" |> Macro.camelize()
    }
  end

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, LiveCommand.execute(event, socket)}
  end

  defp reservation_text(%{time_slot_id: time_slot_id} = _reservation) do
    label =
      Lab.Context.get_time_slot(time_slot_id)
      |> to_option()
      |> Map.get(:label)

    "🗓  #{label}"
  end

  defp action_buttons(%{actions: actions, myself: target}) do
    LiveCommand.action_buttons(actions, target)
  end

  def render(assigns) do
    ~F"""
    <div>
      <div :if={@reservation == nil}>
        <Title3>{dgettext("link-lab", "no.reservation.title")}</Title3>
        <Spacing value="M" />
        <Title6>{dgettext("link-lab", "timeslot.selector.label")}</Title6>
        <Spacing value="XXS" />
        <Dropdown.Selector {...@selector} />
      </div>
      <div :if={@reservation != nil and @status == :pending}>
        <Title3>{dgettext("link-lab", "reservation.title")}</Title3>
        <Spacing value="M" />
        <BodyLarge><span class="whitespace-pre-wrap">{reservation_text(@reservation)}</span></BodyLarge>
        <Spacing value="S" />
      </div>
      <MarginY id={:button_bar_top} />
      <ButtonBar buttons={action_buttons(assigns)} />
    </div>
    """
  end
end
