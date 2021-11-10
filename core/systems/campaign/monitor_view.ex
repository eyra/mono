defmodule Systems.Campaign.MonitorView do
  use CoreWeb.UI.Component

  alias Systems.{
    Crew,
    Campaign
  }

  alias EyraUI.Text.{Title2, Title6, BodyMedium}

  prop(props, :map, required: true)

  data(monitor_data, :any)

  # Handle initial update
  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    preload = Campaign.Model.preload_graph(:full)
    campaign = Campaign.Context.get!(entity_id, preload)
    monitor_data = create(campaign)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(monitor_data: monitor_data)
    }
  end

  def create(
    %{
      promotion: %{
        submission: %{status: status}
      },
      promotable_assignment: %{
        crew: crew,
        assignable_survey_tool: tool
      }
    }
  ) do
    is_active = status === :accepted
    completed = Crew.Context.count_completed_tasks(crew)
    pending = Crew.Context.count_pending_tasks(crew)

    vacant = tool |> get_vacant_count(completed, pending)

    opts =
      %{}
      |> Map.put(:is_active, is_active)
      |> Map.put(:pending_count, pending)
      |> Map.put(:completed_count, completed)
      |> Map.put(:vacant_count, vacant)

    struct(Campaign.MonitorModel, opts)
  end

  defp get_vacant_count(tool, completed, pending) do
    case tool.subject_count do
      count when is_nil(count) -> 0
      count when count > 0 -> count - (completed + pending)
      _ -> 0
    end
  end

  def update() do
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Case value={{ @monitor_data.is_active }} >
          <True>
            <Title2>{{dgettext("link-survey", "status.title")}}</Title2>
            <BodyMedium>{{dgettext("link-survey", "status.label")}}</BodyMedium>
            <Spacing value="XS" />
            <Title6>{{dgettext("link-survey", "completed.label")}}: <span class="text-success"> {{@monitor_data.completed_count}}</span></Title6>
            <Title6>{{dgettext("link-survey", "pending.label")}}: <span class="text-warning"> {{@monitor_data.pending_count}}</span></Title6>
            <Title6>{{dgettext("link-survey", "vacant.label")}}: <span class="text-delete"> {{@monitor_data.vacant_count}}</span></Title6>
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
end
