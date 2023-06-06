defmodule Systems.Campaign.MonitorView do
  use CoreWeb.LiveForm

  import CoreWeb.UI.Empty
  import CoreWeb.UI.Popup
  import CoreWeb.UI.ProgressBar
  alias CoreWeb.UI.Timestamp
  import Systems.Campaign.MonitorTableView

  alias Systems.{
    Pool,
    Crew,
    Campaign,
    Lab
  }

  alias Frameworks.Pixel.Text

  # def update(%{checkin: :new_participant}, socket) do
  #   {
  #     :ok,
  #     socket |> update_vm()
  #   }
  # end

  @impl true
  def update(
        %{reject: :submit, rejection: rejection},
        %{assigns: %{reject_task: task_id}} = socket
      ) do
    Crew.Public.reject_task(task_id, rejection)

    {
      :ok,
      socket
      |> assign(reject_task: nil)
      |> update_entity()
      |> update_vm()
    }
  end

  @impl true
  def update(%{reject: :cancel}, socket) do
    {:ok, socket |> assign(reject_task: nil)}
  end

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity: entity,
          attention_list_enabled?: attention_list_enabled?,
          labels: labels
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        attention_list_enabled?: attention_list_enabled?,
        labels: labels,
        reject_task: nil
      )
      |> update_vm()
    }
  end

  defp update_vm(
         %{assigns: %{entity: entity, attention_list_enabled?: attention_list_enabled?}} = socket
       ) do
    vm =
      socket
      |> to_view_model(entity, attention_list_enabled?)

    socket |> assign(vm: vm)
  end

  defp update_entity(%{assigns: %{entity: %{id: id}}} = socket) do
    entity =
      Campaign.Public.get!(id, Campaign.Model.preload_graph(:full))
      |> Campaign.Model.flatten()

    socket |> assign(entity: entity)
  end

  @impl true
  def handle_event(
        "accept_all_pending_started",
        _params,
        %{assigns: %{vm: %{attention_tasks: tasks}}} = socket
      ) do
    Enum.each(tasks, &Crew.Public.accept_task(&1.id))
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "accept_all_completed",
        _params,
        %{assigns: %{vm: %{completed_tasks: tasks}}} = socket
      ) do
    Enum.each(tasks, &Crew.Public.accept_task(&1.id))

    {
      :noreply,
      socket
      |> update_entity()
      |> update_vm()
    }
  end

  @impl true
  def handle_event("accept", %{"item" => task_id}, socket) do
    Crew.Public.accept_task(task_id)

    {
      :noreply,
      socket
      |> update_entity()
      |> update_vm()
    }
  end

  @impl true
  def handle_event("reject", %{"item" => task_id}, socket) do
    {
      :noreply,
      socket
      |> assign(reject_task: task_id)
    }
  end

  defp lab_tool(%{lab_tool: lab_tool}), do: lab_tool
  defp lab_tool(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @reject_task do %>
        <.popup>
          <.live_component module={Crew.RejectView} id={:reject_view_example} target={%{type: __MODULE__, id: @id}} />
        </.popup>
      <% end %>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if not @vm.active? do %>
          <.empty
              title={dgettext("link-survey", "monitor.empty.title")}
              body={dgettext("link-survey", "monitor.empty.description")}
              illustration="members"
            />
        <% else %>
          <%= if lab_tool(@vm.experiment) do %>
            <.live_component module={Lab.CheckInView}
              id={:search_subject_view}
              tool={lab_tool(@vm.experiment)}
              parent={%{type: __MODULE__, id: @id}}
            />
            <.spacing value="XL" />
          <% end %>

          <Text.title2><%= dgettext("link-monitor", "phase1.title") %></Text.title2>
          <Text.title3 margin="mb-8"><%= dgettext("link-survey", "status.title") %><span class="text-primary">
            <%= @vm.participated_count %>/<%= @vm.progress.size %></span></Text.title3>
          <.spacing value="M" />
          <div class="bg-grey6 rounded p-12">
            <.progress_bar {@vm.progress} />
            <div class="flex flex-row flex-wrap gap-y-4 gap-x-12 mt-12">
              <div>
                <div class="flex flex-row items-center gap-3">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-success" />
                  <Text.label><%= @labels.participated %>: <%= @vm.participated_count %></Text.label>
                </div>
              </div>
              <div>
                <div class="flex flex-row items-center gap-3">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-warning" />
                  <Text.label><%= @labels.pending %>: <%= @vm.pending_count %></Text.label>
                </div>
              </div>
              <div>
                <div class="flex flex-row items-center gap-3">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-grey4" />
                  <Text.label><%= dgettext("link-survey", "vacant.label") %>: <%= @vm.vacant_count %></Text.label>
                </div>
              </div>
            </div>
          </div>
          <.spacing value="XL" />

          <Text.title2><%= dgettext("link-monitor", "phase2.title") %></Text.title2>

          <%= if Enum.count(@vm.attention_tasks) > 0 do %>
            <Text.title3 margin="mb-8">
              <%= dgettext("link-monitor", "attention.title") %><span class="text-primary">
                <%= Enum.count(@vm.attention_tasks) %></span>
            </Text.title3>
            <Text.body_large><%= dgettext("link-monitor", "attention.body") %></Text.body_large>
            <.spacing value="M" />
            <.monitor_table_view columns={@vm.attention_columns} tasks={@vm.attention_tasks} />
            <.spacing value="M" />
            <.wrap>
              <Button.dynamic {%{
                action: %{type: :send, target: @myself, event: "accept_all_pending_started"},
                face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
              }} />
            </.wrap>
            <.spacing value="XL" />
          <% end %>

          <Text.title3 margin="mb-8">
            <%= dgettext("link-monitor", "waitinglist.title") %><span class="text-primary">
              <%= Enum.count(@vm.completed_tasks) %></span>
          </Text.title3>

          <%= if Enum.count(@vm.completed_tasks) > 0 do %>
            <Text.body_large><%= dgettext("link-monitor", "waitinglist.body") %></Text.body_large>
            <.spacing value="M" />
            <.monitor_table_view columns={@vm.completed_columns} tasks={@vm.completed_tasks} />
            <.spacing value="M" />
            <.wrap>
              <Button.dynamic {%{
                action: %{type: :send, target: @myself, event: "accept_all_completed"},
                face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
              }} />
            </.wrap>
            <.spacing value="XL" />
          <% else %>
            <.spacing value="L" />
          <% end %>

          <Text.title3>
            <%= dgettext("link-monitor", "rejected.title") %><span class="text-primary"> <%= Enum.count(@vm.rejected_tasks) %></span>
          </Text.title3>

          <%= if Enum.count(@vm.rejected_tasks) > 0 do %>
            <.monitor_table_view columns={@vm.rejected_columns} tasks={@vm.rejected_tasks} />
            <.spacing value="XL" />
          <% else %>
            <.spacing value="L" />
          <% end %>

          <Text.title3 margin="mb-8">
            <%= dgettext("link-monitor", "accepted.title") %><span class="text-primary">
              <%= Enum.count(@vm.accepted_tasks) %></span>
          </Text.title3>

          <%= if Enum.count(@vm.accepted_tasks) > 0 do %>
            <.monitor_table_view columns={@vm.accepted_columns} tasks={@vm.accepted_tasks} />
          <% end %>>
        <% end %>
      </Area.content>
    </div>
    """
  end

  defp to_view_model(
         %{
           assigns: %{
             myself: target
           }
         },
         %{
           submission: submission,
           promotable: %{
             crew: crew,
             assignable_experiment:
               %{
                 subject_count: subject_count
               } = experiment
           }
         },
         attention_list_enabled?
       ) do
    participated_count = Crew.Public.count_participated_tasks(crew)
    pending_count = Crew.Public.count_pending_tasks(crew)
    vacant_count = experiment |> get_vacant_count(participated_count, pending_count)

    status = Pool.SubmissionModel.status(submission)
    active? = status === :accepted or Crew.Public.active?(crew)

    {attention_columns, attention_tasks} =
      if attention_list_enabled? do
        Crew.Public.expired_pending_started_tasks(crew)
        |> to_view_model(:attention_tasks, target, experiment)
      else
        {[], []}
      end

    {completed_columns, completed_tasks} =
      Crew.Public.completed_tasks(crew)
      |> to_view_model(:completed_tasks, target, experiment)

    {rejected_columns, rejected_tasks} =
      Crew.Public.rejected_tasks(crew)
      |> to_view_model(:rejected_tasks, target, experiment)

    {accepted_columns, accepted_tasks} =
      Crew.Public.accepted_tasks(crew)
      |> to_view_model(:accepted_tasks, target, experiment)

    %{
      experiment: experiment,
      active?: active?,
      subject_count: subject_count,
      pending_count: pending_count,
      participated_count: participated_count,
      vacant_count: vacant_count,
      attention_columns: attention_columns,
      attention_tasks: attention_tasks,
      completed_columns: completed_columns,
      completed_tasks: completed_tasks,
      rejected_columns: rejected_columns,
      rejected_tasks: rejected_tasks,
      accepted_columns: accepted_columns,
      accepted_tasks: accepted_tasks,
      progress: %{
        size: max(subject_count, participated_count + pending_count),
        bars: [
          %{
            color: :warning,
            size: participated_count + pending_count
          },
          %{
            color: :success,
            size: participated_count
          }
        ]
      }
    }
  end

  defp get_vacant_count(%{subject_count: subject_count} = _experiment, finished, pending) do
    case subject_count do
      count when is_nil(count) -> 0
      count when count > 0 -> max(0, count - (finished + pending))
      _ -> 0
    end
  end

  defp is_lab_experiment(%{lab_tool_id: lab_tool_id} = _experiment), do: lab_tool_id != nil

  defp reservation(%{lab_tool_id: lab_tool_id} = _experiment, user_id) when lab_tool_id != nil do
    tool = Lab.Public.get(lab_tool_id)
    user = Core.Accounts.get_user!(user_id)
    Lab.Public.reservation_for_user(tool, user)
  end

  defp reservation(_experiment, _user_id), do: nil

  defp time_slot(nil), do: nil

  defp time_slot(%{time_slot_id: time_slot_id} = _reservation) do
    Lab.Public.get_time_slot(time_slot_id)
  end

  defp time_slot_message(nil), do: "Participated without reservation"
  defp time_slot_message(time_slot), do: "🗓  " <> Lab.TimeSlotModel.message(time_slot)

  defp to_view_model([], _, _, _), do: {[], []}

  defp to_view_model(tasks, :attention_tasks, target, experiment) do
    columns = [
      dgettext("link-monitor", "column.participant"),
      dgettext("link-monitor", "column.message")
    ]

    tasks = Enum.map(tasks, &to_view_model(:attention, target, experiment, &1))
    {columns, tasks}
  end

  defp to_view_model(tasks, :completed_tasks, target, experiment) do
    columns =
      if is_lab_experiment(experiment) do
        [
          dgettext("link-monitor", "column.participant"),
          dgettext("link-monitor", "column.reservation"),
          dgettext("link-monitor", "column.checkedin")
        ]
      else
        ["Subject", "Finished"]
      end

    tasks = Enum.map(tasks, &to_view_model(:waitinglist, target, experiment, &1))

    {columns, tasks}
  end

  defp to_view_model(tasks, :rejected_tasks, target, experiment) do
    columns = [
      dgettext("link-monitor", "column.participant"),
      dgettext("link-monitor", "column.reason"),
      dgettext("link-monitor", "column.rejected")
    ]

    tasks = Enum.map(tasks, &to_view_model(:rejected, target, experiment, &1))
    {columns, tasks}
  end

  defp to_view_model(tasks, :accepted_tasks, target, experiment) do
    columns = [
      dgettext("link-monitor", "column.participant"),
      dgettext("link-monitor", "column.accepted")
    ]

    tasks = Enum.map(tasks, &to_view_model(:accepted, target, experiment, &1))
    {columns, tasks}
  end

  defp to_view_model(:attention, target, _experiment, %Crew.TaskModel{
         id: id,
         started_at: started_at,
         member_id: member_id
       }) do
    %{public_id: public_id} = Crew.Public.get_member!(member_id)

    date_string =
      started_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()

    message_text = dgettext("link-monitor", "started.at.message", date: date_string)

    %{
      id: id,
      public_id: public_id,
      message: %{type: :warning, text: message_text},
      buttons: [accept_button(id, target), reject_button(id, target)]
    }
  end

  defp to_view_model(:waitinglist, target, experiment, %Crew.TaskModel{
         id: id,
         completed_at: completed_at,
         member_id: member_id
       }) do
    %{user_id: user_id, public_id: public_id} = Crew.Public.get_member!(member_id)

    description =
      if is_lab_experiment(experiment) do
        if reservation = reservation(experiment, user_id) do
          time_slot(reservation)
          |> time_slot_message()
        else
          "-"
        end
      else
        nil
      end

    date_string =
      completed_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()
      |> String.capitalize()

    %{
      id: id,
      public_id: public_id,
      description: description,
      message: %{text: date_string},
      buttons: [accept_button(id, target), reject_button(id, target)]
    }
  end

  defp to_view_model(:rejected, target, _experiment, %Crew.TaskModel{
         id: id,
         rejected_category: rejected_category,
         rejected_message: rejected_message,
         rejected_at: rejected_at,
         member_id: member_id
       }) do
    %{public_id: public_id} = Crew.Public.get_member!(member_id)

    date_string =
      rejected_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()
      |> String.capitalize()

    icon = Crew.RejectCategories.icon(rejected_category)
    description = "#{icon} #{rejected_message}"

    %{
      id: id,
      public_id: public_id,
      description: description,
      message: %{text: date_string},
      buttons: [accept_button(id, target)]
    }
  end

  defp to_view_model(:accepted, _target, _experiment, %Crew.TaskModel{
         id: id,
         accepted_at: accepted_at,
         member_id: member_id
       }) do
    %{public_id: public_id} = Crew.Public.get_member!(member_id)

    date_string =
      accepted_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()
      |> String.capitalize()

    %{
      id: id,
      message: %{text: date_string},
      public_id: public_id,
      buttons: []
    }
  end

  defp accept_button(id, target) do
    %{
      action: %{type: :send, item: id, target: target, event: "accept"},
      face: %{type: :icon, icon: :accept}
    }
  end

  defp reject_button(id, target) do
    %{
      action: %{type: :send, item: id, target: target, event: "reject"},
      face: %{type: :icon, icon: :reject}
    }
  end
end
