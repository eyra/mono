defmodule Systems.Campaign.MonitorView do
  use CoreWeb.LiveForm

  alias CoreWeb.UI.{Timestamp, ProgressBar, Popup}
  alias Frameworks.Pixel.Container.Wrap

  alias Systems.{
    Crew,
    Campaign,
    Lab
  }

  alias Frameworks.Pixel.Text.{Title2, Title3, BodyLarge, Label}

  prop(props, :map, required: true)

  data(vm, :any)
  data(reject_task, :number)
  data(labels, :list)

  def update(%{checkin: :new_participant}, socket) do
    {
      :ok,
      socket |> update_vm()
    }
  end

  def update(
        %{reject: :submit, rejection: rejection},
        %{assigns: %{reject_task: task_id}} = socket
      ) do
    Crew.Context.reject_task(task_id, rejection)

    {
      :ok,
      socket
      |> assign(reject_task: nil)
      |> update_vm()
    }
  end

  def update(%{reject: :cancel}, socket) do
    {:ok, socket |> assign(reject_task: nil)}
  end

  # Handle initial update
  def update(
        %{
          id: id,
          props: %{
            entity_id: entity_id,
            attention_list_enabled?: attention_list_enabled?,
            labels: labels
          }
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        attention_list_enabled?: attention_list_enabled?,
        labels: labels,
        reject_task: nil
      )
      |> update_vm()
    }
  end

  defp update_vm(%{assigns: %{entity_id: entity_id}} = socket) do
    preload = Campaign.Model.preload_graph(:full)
    campaign = Campaign.Context.get!(entity_id, preload)
    vm = to_view_model(socket, campaign)

    assign(socket, vm: vm)
  end

  @impl true
  def handle_event(
        "accept_all_pending_started",
        _params,
        %{assigns: %{vm: %{attention_tasks: tasks}}} = socket
      ) do
    Enum.each(tasks, &Crew.Context.accept_task(&1.id))

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def handle_event(
        "accept_all_completed",
        _params,
        %{assigns: %{vm: %{completed_tasks: tasks}}} = socket
      ) do
    Enum.each(tasks, &Crew.Context.accept_task(&1.id))

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def handle_event("accept", %{"item" => task_id}, socket) do
    Crew.Context.accept_task(task_id)

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def handle_event("reject", %{"item" => task_id}, socket) do
    {
      :noreply,
      socket |> assign(reject_task: task_id)
    }
  end

  defp lab_tool(%{lab_tool: lab_tool}), do: lab_tool
  defp lab_tool(_), do: nil

  @impl true
  def render(assigns) do
    ~F"""
      <Popup :if={@reject_task != nil}>
        <Crew.RejectView id={:reject_view_example} target={%{type: __MODULE__, id: @id}} />
      </Popup>
      <ContentArea>
        <MarginY id={:page_top} />
        <Case value={@vm.active?} >
          <True>
            <div :if={lab_tool(@vm.experiment) != nil}>
              <Lab.CheckInView id={:search_subject_view} tool={lab_tool(@vm.experiment)} parent={%{type: __MODULE__, id: @id}} />
              <Spacing value="XL" />
            </div>

            <Title2>{dgettext("link-monitor", "phase1.title")}</Title2>
            <Title3 margin={"mb-8"}>{dgettext("link-survey", "status.title")}<span class="text-primary"> {@vm.participated_count}/{@vm.progress.size}</span></Title3>
            <Spacing value="M" />
            <div class="bg-grey6 rounded p-12">
              <ProgressBar {...@vm.progress} />
              <div class="flex flex-row flex-wrap gap-y-4 gap-x-12 mt-12">
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-success"></div>
                    <Label>{@labels.participated}: {@vm.participated_count}</Label>
                  </div>
                </div>
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-warning"></div>
                    <Label>{@labels.pending}: {@vm.pending_count}</Label>
                  </div>
                </div>
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-grey4"></div>
                    <Label>{dgettext("link-survey", "vacant.label")}: {@vm.vacant_count}</Label>
                  </div>
                </div>
              </div>
            </div>
            <Spacing value="XL" />

            <Title2>{dgettext("link-monitor", "phase2.title")}</Title2>

            <div :if={Enum.count(@vm.attention_tasks) > 0}>
              <Title3 margin={"mb-8"}>
                {dgettext("link-monitor", "attention.title")}<span class="text-primary"> {Enum.count(@vm.attention_tasks)}</span>
              </Title3>
              <BodyLarge>{dgettext("link-monitor", "attention.body")}</BodyLarge>
              <Spacing value="M" />
              <Campaign.MonitorTableView columns={@vm.attention_columns} tasks={@vm.attention_tasks} />
              <Spacing value="M" />
              <Wrap>
                <DynamicButton vm={%{
                  action: %{ type: :send, target: @myself, event: "accept_all_pending_started"},
                  face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
                }} />
              </Wrap>
              <Spacing value="XL" />
            </div>

            <Title3 margin={"mb-8"}>
              {dgettext("link-monitor", "waitinglist.title")}<span class="text-primary"> {Enum.count(@vm.completed_tasks)}</span>
            </Title3>
            <div :if={Enum.count(@vm.completed_tasks) > 0}>
              <BodyLarge>{dgettext("link-monitor", "waitinglist.body")}</BodyLarge>
              <Spacing value="M" />
              <Campaign.MonitorTableView columns={@vm.completed_columns} tasks={@vm.completed_tasks} />
              <Spacing value="M" />
              <Wrap>
                <DynamicButton vm={%{
                  action: %{ type: :send, target: @myself, event: "accept_all_completed"},
                  face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
                }} />
              </Wrap>
              <Spacing value="XL" />
            </div>
            <div :if={Enum.count(@vm.completed_tasks) == 0}>
              <Spacing value="L" />
            </div>

            <Title3>
              {dgettext("link-monitor", "rejected.title")}<span class="text-primary"> {Enum.count(@vm.rejected_tasks)}</span>
            </Title3>
            <div :if={Enum.count(@vm.rejected_tasks) > 0}>
              <Campaign.MonitorTableView columns={@vm.rejected_columns} tasks={@vm.rejected_tasks} />
              <Spacing value="XL" />
            </div>
            <div :if={Enum.count(@vm.rejected_tasks) == 0}>
              <Spacing value="L" />
            </div>

            <Title3 margin={"mb-8"}>
              {dgettext("link-monitor", "accepted.title")}<span class="text-primary"> {Enum.count(@vm.accepted_tasks)}</span>
            </Title3>
            <div :if={Enum.count(@vm.accepted_tasks) > 0}>
              <Campaign.MonitorTableView columns={@vm.accepted_columns} tasks={@vm.accepted_tasks} />
            </div>
          </True>
          <False>
            <Empty
              title={dgettext("link-survey", "monitor.empty.title")}
              body={dgettext("link-survey", "monitor.empty.description")}
              illustration="members"
            />
          </False>
        </Case>
      </ContentArea>
    """
  end

  defp to_view_model(
         %{
           assigns: %{
             attention_list_enabled?: attention_list_enabled?,
             myself: target
           }
         },
         %{
           promotion: %{
             submission: %{status: status}
           },
           promotable_assignment: %{
             crew: crew,
             assignable_experiment:
               %{
                 subject_count: subject_count
               } = experiment
           }
         }
       ) do
    participated_count = Crew.Context.count_participated_tasks(crew)
    pending_count = Crew.Context.count_pending_tasks(crew)
    vacant_count = experiment |> get_vacant_count(participated_count, pending_count)

    active? = status === :accepted or Crew.Context.active?(crew)

    {attention_columns, attention_tasks} =
      if attention_list_enabled? do
        Crew.Context.expired_pending_started_tasks(crew)
        |> to_view_model(:attention_tasks, target, experiment)
      else
        {[], []}
      end

    {completed_columns, completed_tasks} =
      Crew.Context.completed_tasks(crew)
      |> to_view_model(:completed_tasks, target, experiment)

    {rejected_columns, rejected_tasks} =
      Crew.Context.rejected_tasks(crew)
      |> to_view_model(:rejected_tasks, target, experiment)

    {accepted_columns, accepted_tasks} =
      Crew.Context.accepted_tasks(crew)
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
    tool = Lab.Context.get(lab_tool_id)
    user = Core.Accounts.get_user!(user_id)
    Lab.Context.reservation_for_user(tool, user)
  end

  defp reservation(_experiment, _user_id), do: nil

  defp time_slot(nil), do: nil

  defp time_slot(%{time_slot_id: time_slot_id} = _reservation) do
    Lab.Context.get_time_slot(time_slot_id)
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
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

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
    %{user_id: user_id, public_id: public_id} = Crew.Context.get_member!(member_id)

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
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

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
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

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
