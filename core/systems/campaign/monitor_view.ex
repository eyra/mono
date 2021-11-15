defmodule Systems.Campaign.MonitorView do
  use CoreWeb.LiveForm

  alias CoreWeb.UI.Timestamp
  alias EyraUI.Container.Wrap

  alias Systems.{
    Crew,
    Campaign
  }

  alias EyraUI.Text.{Title3, BodyMedium, BodyLarge}

  prop(props, :map, required: true)
  data(vm, :any)

  # Handle initial update
  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id
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
  def handle_event("accept_all", _params, %{assigns: %{vm: %{pending_started_tasks: tasks}}} = socket) do
    Enum.each(tasks, &Crew.Context.complete_task!(&1.id))

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def handle_event("accept", %{"item" => task_id}, socket) do
    Crew.Context.get_task!(task_id)
    |> Crew.Context.complete_task!()

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def handle_event("reject", %{"item" => task_id}, socket) do
    Crew.Context.mark_expired(task_id)

    {
      :noreply,
      socket |> update_vm()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Case value={{ @vm.is_active }} >
          <True>
            <Title3 margin={{"mb-8"}}>{{dgettext("link-survey", "status.title")}}<span class="text-primary"> {{@vm.completed_count}}/{{@vm.subject_count}}</span></Title3>
            <BodyLarge>{{dgettext("link-survey", "status.label")}}</BodyLarge>
            <Spacing value="M" />
            <BodyMedium>{{dgettext("link-survey", "completed.label")}}: <span class="text-success"> {{@vm.completed_count}}</span></BodyMedium>
            <Spacing value="XS" />
            <BodyMedium>{{dgettext("link-survey", "pending.label")}}: <span class="text-warning"> {{@vm.pending_count}}</span></BodyMedium>
            <Spacing value="XS" />
            <BodyMedium>{{dgettext("link-survey", "vacant.label")}}: <span class="text-delete"> {{@vm.vacant_count}}</span></BodyMedium>
            <Spacing value="XL" />

            <Title3 margin={{"mb-8"}}>
              {{dgettext("link-monitor", "attention.title")}}<span class="text-primary"> {{ Enum.count(@vm.pending_started_tasks) }}</span>
            </Title3>
            <div :if={{ Enum.count(@vm.pending_started_tasks) > 0 }}>
              <BodyLarge>{{dgettext("link-monitor", "attention.body")}}</BodyLarge>
              <Spacing value="M" />
              <Wrap>
                <DynamicButton vm={{ %{
                  action: %{ type: :send, target: @myself, event: "accept_all"},
                  face: %{type: :primary, label: dgettext("link-monitor", "accept.all.button")}
                } }} />
              </Wrap>
              <Spacing value="M" />
            </div>
            <div class="flex flex-col gap-6">
              <div :for={{ task <- @vm.pending_started_tasks }}>
                <div class="flex flex-row gap-5 items-center">
                  <div class="flex-wrap">
                    <BodyLarge>Subject {{ task.member_public_id }}</BodyLarge>
                  </div>
                  <div class="flex-wrap">
                    <BodyMedium color={{"text-warning"}}>⚠️ {{ task.message }}</BodyMedium>
                  </div>
                  <div class="flex-grow"></div>
                  <div class="flex-wrap">
                    <DynamicButton vm={{task.accept_button}} />
                  </div>
                  <div class="flex-wrap">
                    <DynamicButton vm={{task.reject_button}} />
                  </div>
                </div>
              </div>
            </div>
          </True>
          <False>
            <Empty
              title={{ dgettext("link-survey", "monitor.empty.title") }}
              body={{ dgettext("link-survey", "monitor.empty.description") }}
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
        assignable_survey_tool: %{
          subject_count: subject_count
        } = tool
      }
    }
  ) do
    is_active = status === :accepted
    completed_count = Crew.Context.count_completed_tasks(crew)
    pending_count = Crew.Context.count_pending_tasks(crew)
    vacant_count = tool |> get_vacant_count(completed_count, pending_count)

    pending_started_tasks =
      Crew.Context.pending_started_tasks(crew)
      |> to_view_model(:pending_started_tasks, target)

    %{
      is_active: is_active,
      subject_count: subject_count,
      pending_count: pending_count,
      completed_count: completed_count,
      vacant_count: vacant_count,
      pending_started_tasks: pending_started_tasks
    }
  end

  defp get_vacant_count(tool, completed, pending) do
    case tool.subject_count do
      count when is_nil(count) -> 0
      count when count > 0 -> count - (completed + pending)
      _ -> 0
    end
  end

  defp to_view_model([], :pending_started_tasks, _), do: []
  defp to_view_model(tasks, :pending_started_tasks, target) do
    Enum.map(tasks, &to_view_model(&1, :attention, target))
  end

  defp to_view_model(
    %Crew.TaskModel{
      id: id,
      started_at: started_at,
      member_id: member_id
    },
    :attention,
    target
  ) do
    %{public_id: public_id} = Crew.Context.get_member!(member_id)

    date_string = started_at |> Timestamp.humanize()

    %{
      id: id,
      member_public_id: public_id,
      message: dgettext("link-monitor", "started.at.message", date: date_string),
      accept_button: %{
        action: %{
          type: :send,
          item: id,
          target: target,
          event: "accept"
        },
        face: %{
          type: :icon,
          icon: :accept
        }
      },
      reject_button: %{
        action: %{
          type: :send,
          item: id,
          target: target,
          event: "reject"
        },
        face: %{
          type: :icon,
          icon: :reject
        }
      }
    }
  end
end
