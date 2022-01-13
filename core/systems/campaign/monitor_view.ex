defmodule Systems.Campaign.MonitorView do
  use CoreWeb.LiveForm

  alias CoreWeb.UI.{Timestamp, ProgressBar, Popup}
  alias Frameworks.Pixel.Container.Wrap

  alias Systems.{
    Crew,
    Campaign
  }

  alias Frameworks.Pixel.Text.{Title2, Title3, BodyLarge, Label}

  prop(props, :map, required: true)
  data(vm, :any)
  data(reject_task, :number)

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
  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
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
        %{assigns: %{vm: %{pending_started_tasks: tasks}}} = socket
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
            <Title2>{dgettext("link-monitor", "phase1.title")}</Title2>
            <Title3 margin={"mb-8"}>{dgettext("link-survey", "status.title")}<span class="text-primary"> {@vm.finished_count}/{@vm.subject_count}</span></Title3>
            <Spacing value="M" />
            <div class="bg-grey6 rounded p-12">
              <ProgressBar {...@vm.progress} />
              <div class="flex flex-row flex-wrap gap-y-4 gap-x-12">
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-success"></div>
                    <Label>{dgettext("link-survey", "completed.label")}: {@vm.finished_count}</Label>
                  </div>
                </div>
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-warning"></div>
                    <Label>{dgettext("link-survey", "started.label")}: {@vm.started_count}</Label>
                  </div>
                </div>
                <div>
                  <div class="flex flex-row items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-tertiary"></div>
                    <Label>{dgettext("link-survey", "pending.label")}: {@vm.applied_count}</Label>
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

            <div :if={Enum.count(@vm.pending_started_tasks) > 0}>
              <Title3 margin={"mb-8"}>
                {dgettext("link-monitor", "attention.title")}<span class="text-primary"> {Enum.count(@vm.pending_started_tasks)}</span>
              </Title3>
              <BodyLarge>{dgettext("link-monitor", "attention.body")}</BodyLarge>
              <Spacing value="M" />
              <Wrap>
                <DynamicButton vm={%{
                  action: %{ type: :send, target: @myself, event: "accept_all_pending_started"},
                  face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
                }} />
              </Wrap>
              <Spacing value="M" />
              <div class="flex flex-col gap-6">
                <div :for={task <- @vm.pending_started_tasks}>
                  <Crew.TaskItemView {...task} />
                </div>
              </div>
              <Spacing value="XL" />
            </div>

            <Title3 margin={"mb-8"}>
              {dgettext("link-monitor", "waitinglist.title")}<span class="text-primary"> {Enum.count(@vm.completed_tasks)}</span>
            </Title3>
            <div :if={Enum.count(@vm.completed_tasks) > 0}>
              <BodyLarge>{dgettext("link-monitor", "waitinglist.body")}</BodyLarge>
              <Spacing value="M" />
              <Wrap>
                <DynamicButton vm={%{
                  action: %{ type: :send, target: @myself, event: "accept_all_completed"},
                  face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
                }} />
              </Wrap>
              <Spacing value="M" />
            </div>
            <div :if={Enum.count(@vm.completed_tasks) > 0}>
              <div class="flex flex-col gap-6">
                <div :for={task <- @vm.completed_tasks}>
                  <Crew.TaskItemView {...task} />
                </div>
              </div>
              <Spacing value="XL" />
            </div>
            <div :if={Enum.count(@vm.completed_tasks) == 0}>
              <Spacing value="L" />
            </div>

            <Title3>
              {dgettext("link-monitor", "rejected.title")}<span class="text-primary"> {Enum.count(@vm.rejected_tasks)}</span>
            </Title3>
            <div :if={Enum.count(@vm.rejected_tasks) > 0}>
              <div class="flex flex-col gap-6">
                <div :for={task <- @vm.rejected_tasks}>
                  <Crew.TaskItemView {...task} />
                </div>
              </div>
              <Spacing value="XL" />
            </div>
            <div :if={Enum.count(@vm.rejected_tasks) == 0}>
              <Spacing value="L" />
            </div>

            <Title3 margin={"mb-8"}>
              {dgettext("link-monitor", "accepted.title")}<span class="text-primary"> {Enum.count(@vm.accepted_tasks)}</span>
            </Title3>
            <div class="flex flex-col gap-6">
              <div :for={task <- @vm.accepted_tasks}>
                <Crew.TaskItemView {...task} />
              </div>
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
               } = tool
           }
         }
       ) do
    finished_count = Crew.Context.count_finished_tasks(crew)
    started_count = Crew.Context.count_started_tasks(crew)
    applied_count = Crew.Context.count_applied_tasks(crew)
    vacant_count = tool |> get_vacant_count(finished_count, started_count, applied_count)

    active? = status === :accepted or Crew.Context.active?(crew)

    pending_started_tasks =
      Crew.Context.expired_pending_started_tasks(crew)
      |> to_view_model(:expired_pending_started_tasks, target)

    completed_tasks =
      Crew.Context.completed_tasks(crew)
      |> to_view_model(:completed_tasks, target)

    rejected_tasks =
      Crew.Context.rejected_tasks(crew)
      |> to_view_model(:rejected_tasks, target)

    accepted_tasks =
      Crew.Context.accepted_tasks(crew)
      |> to_view_model(:accepted_tasks, target)

    %{
      active?: active?,
      subject_count: subject_count,
      applied_count: applied_count,
      started_count: started_count,
      finished_count: finished_count,
      vacant_count: vacant_count,
      pending_started_tasks: pending_started_tasks,
      completed_tasks: completed_tasks,
      rejected_tasks: rejected_tasks,
      accepted_tasks: accepted_tasks,
      progress: %{
        size: subject_count,
        bars: [
          %{
            color: :tertiary,
            size: finished_count + started_count + applied_count
          },
          %{
            color: :warning,
            size: finished_count + started_count
          },
          %{
            color: :success,
            size: finished_count
          }
        ]
      }
    }
  end

  defp get_vacant_count(tool, finished, started, applied) do
    case tool.subject_count do
      count when is_nil(count) -> 0
      count when count > 0 -> count - (finished + started + applied)
      _ -> 0
    end
  end

  defp to_view_model([], _, _), do: []

  defp to_view_model(tasks, :expired_pending_started_tasks, target) do
    Enum.map(tasks, &to_view_model(:attention, target, &1))
  end

  defp to_view_model(tasks, :completed_tasks, target) do
    Enum.map(tasks, &to_view_model(:waitinglist, target, &1))
  end

  defp to_view_model(tasks, :rejected_tasks, target) do
    Enum.map(tasks, &to_view_model(:rejected, target, &1))
  end

  defp to_view_model(tasks, :accepted_tasks, target) do
    Enum.map(tasks, &to_view_model(:accepted, target, &1))
  end

  defp to_view_model(:attention, target, %Crew.TaskModel{
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

  defp to_view_model(:waitinglist, target, %Crew.TaskModel{
         id: id,
         member_id: member_id
       }) do
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

    %{
      id: id,
      public_id: public_id,
      buttons: [accept_button(id, target), reject_button(id, target)]
    }
  end

  defp to_view_model(:rejected, target, %Crew.TaskModel{
         id: id,
         rejected_category: rejected_category,
         rejected_message: rejected_message,
         member_id: member_id
       }) do
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

    message_type =
      case rejected_category do
        :other -> :rejected
        category -> category
      end

    %{
      id: id,
      public_id: public_id,
      message: %{type: message_type, text: rejected_message},
      buttons: [accept_button(id, target)]
    }
  end

  defp to_view_model(:accepted, target, %Crew.TaskModel{
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
      buttons: [reject_button(id, target)]
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
