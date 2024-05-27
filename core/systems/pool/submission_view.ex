defmodule Systems.Pool.SubmissionView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form

  import CoreWeb.UI.Timestamp,
    only: [
      now: 0,
      one_week_after: 1,
      parse_user_input_date: 1,
      format_user_input_date: 1,
      before?: 2
    ]

  alias Systems.Pool

  defp determine_new_end(_, nil), do: nil
  defp determine_new_end(nil, schedule_end), do: schedule_end

  defp determine_new_end(schedule_start, schedule_end) do
    if before?(schedule_end, schedule_start) do
      format_user_input_date(one_week_after(schedule_start))
    else
      schedule_end
    end
  end

  # Handle update from parent after attempt to publish
  @impl true
  def update(%{validate?: new}, %{assigns: %{validate?: current}} = socket)
      when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
      |> validate_for_publish()
    }
  end

  @impl true
  def update(
        %{
          id: id,
          entity:
            %{
              schedule_start: schedule_start,
              schedule_end: schedule_end,
              pool: %{currency: %{type: currency_type}}
            } = entity,
          validate?: validate?
        },
        socket
      ) do
    render_reward? = currency_type == :virtual
    changeset = Pool.SubmissionModel.changeset(entity, %{})
    schedule_start_disabled = schedule_start == nil

    schedule_start_toggle_labels = [
      %{
        id: :schedule_start_toggle,
        value: dgettext("eyra-submission", "schedule.start.label"),
        active: not schedule_start_disabled
      }
    ]

    schedule_end_disabled = schedule_end == nil

    schedule_end_toggle_labels = [
      %{
        id: :schedule_end_toggle,
        value: dgettext("eyra-submission", "schedule.end.label"),
        active: not schedule_end_disabled
      }
    ]

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        render_reward?: render_reward?,
        schedule_start_toggle_labels: schedule_start_toggle_labels,
        schedule_start_disabled: schedule_start_disabled,
        schedule_end_toggle_labels: schedule_end_toggle_labels,
        schedule_end_disabled: schedule_end_disabled,
        changeset: changeset,
        validate?: validate?
      )
      |> compose_child(:schedule_start_toggle)
      |> compose_child(:schedule_end_toggle)
      |> validate_for_publish()
    }
  end

  @impl true
  def compose(:schedule_start_toggle, %{schedule_start_toggle_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :checkbox
      }
    }
  end

  @impl true
  def compose(:schedule_end_toggle, %{schedule_end_toggle_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :checkbox
      }
    }
  end

  defp update_ui(
         %{assigns: %{entity: %{schedule_start: schedule_start, schedule_end: schedule_end}}} =
           socket
       ) do
    socket
    |> assign(
      schedule_start_disabled: schedule_start == nil,
      schedule_end_disabled: schedule_end == nil
    )
  end

  # Validate

  def validate_for_publish(%{assigns: %{entity: entity}} = socket) do
    changeset =
      Pool.SubmissionModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    socket
    |> assign(changeset: changeset)
  end

  # Events

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: [], source: %{name: :schedule_start_toggle}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, %{schedule_start: nil})
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: [_], source: %{name: :schedule_start_toggle}},
        %{assigns: %{entity: entity}} = socket
      ) do
    schedule_start = format_user_input_date(now())
    schedule_end = determine_new_end(schedule_start, entity.schedule_end)

    attrs = %{
      schedule_start: schedule_start,
      schedule_end: schedule_end
    }

    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: [], source: %{name: :schedule_end_toggle}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, %{schedule_end: nil})
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: [_], source: %{name: :schedule_end_toggle}},
        %{assigns: %{entity: entity}} = socket
      ) do
    base_date =
      case entity.schedule_start do
        nil -> now()
        date -> parse_user_input_date(date)
      end

    schedule_end = format_user_input_date(one_week_after(base_date))
    attrs = %{schedule_end: schedule_end}

    {
      :ok,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  @impl true
  def handle_event("save", %{"submission_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  def save(socket, %Pool.SubmissionModel{} = entity, attrs) do
    changeset = Pool.SubmissionModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
    |> update_ui()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <%= if @render_reward? do %>
          <Text.title3 margin="mb-5 sm:mb-8"><%= dgettext("eyra-submission", "reward.label") %></Text.title3>
          <.number_input form={form}
            field={:reward_value}
            label_text={dgettext("eyra-submission", "reward.value.label")}
          />
          <.spacing value="M" />
        <% end %>

        <Text.title3 margin="mb-5 sm:mb-8"><%= dgettext("eyra-submission", "schedule.title") %></Text.title3>
        <Text.body><%= dgettext("eyra-submission", "schedule.description") %></Text.body>
        <.spacing value="S" />

        <div class="flex flex-col gap-y-2 sm:flex-row items-left w-full sm:w-form">
          <div class="flex-wrap mt-2">
            <.child name={:schedule_start_toggle} fabric={@fabric} />
          </div>
          <div class="flex-grow">
          </div>
          <div class="flex-wrap h-full">
            <.date_input form={form} field={:schedule_start} disabled={@schedule_start_disabled} />
          </div>
        </div>

        <div class="flex flex-col gap-y-2 sm:flex-row items-left w-full sm:w-form">
          <div class="flex-wrap mt-2">
            <.child name={:schedule_end_toggle} fabric={@fabric} />
          </div>
          <div class="flex-grow">
          </div>
          <div class="flex-wrap h-full">
            <.date_input form={form} field={:schedule_end} disabled={@schedule_end_disabled} />
          </div>
        </div>
      </.form>
      </Area.content>
    </div>
    """
  end
end
