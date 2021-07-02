defmodule CoreWeb.Survey.Monitor do
  use Surface.Component

  import CoreWeb.Gettext

  alias EyraUI.Spacing
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title3, Title6, BodyMedium}

  prop(monitor_data, :any, required: true)

  def render(assigns) do
    ~H"""
    <If condition={{ @monitor_data.is_published }} >
      <ContentArea>
        <Title3>{{dgettext("eyra-survey", "status.title")}}</Title3>
        <BodyMedium>{{dgettext("eyra-survey", "status.label")}}</BodyMedium>
        <Spacing value="XS" />
        <Title6>{{dgettext("eyra-survey", "completed.label")}}: <span class="text-success"> {{@monitor_data.subject_completed_count}}</span></Title6>
        <Title6>{{dgettext("eyra-survey", "pending.label")}}: <span class="text-warning"> {{@monitor_data.subject_pending_count}}</span></Title6>
        <Title6>{{dgettext("eyra-survey", "vacant.label")}}: <span class="text-delete"> {{@monitor_data.subject_vacant_count}}</span></Title6>
      </ContentArea>
    </If>
    """
  end
end
