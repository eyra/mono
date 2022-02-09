defmodule Systems.Lab.ExperimentTaskView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title3, Title6, BodyLarge}
  alias Frameworks.Pixel.Dropdown

  alias Systems.{
    Lab
  }

  prop(lab_tool, :map, required: true)
  prop(contact_enabled?, :boolean, required: true)
  prop(reservation, :any, required: true)
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

  def update(%{model: %{lab_tool: lab_tool, reservation: reservation}}, socket) do
    {
      :ok,
      socket
      |> assign(
        lab_tool: lab_tool,
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
          contact_enabled?: contact_enabled?,
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
        contact_enabled?: contact_enabled?,
        reservation: reservation,
        user: user,
        lock_ui: false
      )
      |> update_time_slots()
      |> init_selector()
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

  def handle_event("submit", _params, %{assigns: %{selected_time_slot: nil}} = socket) do
    warning = dgettext("link-lab", "submit.warning.no.selection")
    send_update(Dropdown.Selector, id: :dropdown_selector, model: %{warning: warning})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit",
        _params,
        %{assigns: %{selected_time_slot: time_slot, user: user}} = socket
      ) do
    Lab.Context.reserve_time_slot(time_slot, user)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _params, %{assigns: %{lab_tool: lab_tool, user: user}} = socket) do
    Lab.Context.cancel_reservation(lab_tool, user)
    {:noreply, socket |> assign(selected_time_slot: nil)}
  end

  defp submit_button(%{myself: myself}) do
    %{
      action: %{type: :send, event: "submit", target: myself},
      face: %{
        type: :primary,
        label: dgettext("link-lab", "timeslot.submit.button")
      }
    }
  end

  defp cancel_button(%{myself: myself}) do
    %{
      action: %{type: :send, event: "cancel", target: myself},
      face: %{
        type: :secondary,
        text_color: "text-delete",
        label: dgettext("eyra-assignment", "cancel.button")
      }
    }
  end

  defp reservation_text(%{time_slot_id: time_slot_id} = _reservation) do
    label =
      Lab.Context.get_time_slot(time_slot_id)
      |> to_option()
      |> Map.get(:label)

    "🗓  #{label}"
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
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={submit_button(assigns)} />
        </Wrap>
      </div>
      <div :if={@reservation}>
        <Title3>{dgettext("link-lab", "reservation.title")}</Title3>
        <Spacing value="M" />
        <BodyLarge><span class="whitespace-pre-wrap">{reservation_text(@reservation)}</span></BodyLarge>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={cancel_button(assigns)} />
        </Wrap>
        </div>
    </div>
    """
  end
end
