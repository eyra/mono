defmodule Link.Survey.Monitor do
  use Surface.Component

  import CoreWeb.Gettext

  alias EyraUI.Spacing
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title2, Title6, BodyMedium}

  prop(monitor_data, :any, required: true)

  def render(assigns) do
    ~H"""
    <If condition={{ @monitor_data.is_published }} >
      <ContentArea>
        <Title2>{{dgettext("link-survey", "status.title")}}</Title2>
        <BodyMedium>{{dgettext("link-survey", "status.label")}}</BodyMedium>
        <Spacing value="XS" />
        <Title6>{{dgettext("link-survey", "completed.label")}}: <span class="text-success"> {{@monitor_data.subject_completed_count}}</span></Title6>
        <Title6>{{dgettext("link-survey", "pending.label")}}: <span class="text-warning"> {{@monitor_data.subject_pending_count}}</span></Title6>
        <Title6>{{dgettext("link-survey", "vacant.label")}}: <span class="text-delete"> {{@monitor_data.subject_vacant_count}}</span></Title6>
      </ContentArea>
    </If>
    """
  end
end
