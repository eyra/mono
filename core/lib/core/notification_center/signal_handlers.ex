defmodule Core.NotificationCenter.SignalHandlers do
  use Core.Signals.Handlers
  import Core.NotificationCenter, only: [notify_users_with_role: 3]

  alias Core.Studies

  @impl true
  def dispatch(:participant_applied, %{survey_tool: survey_tool}) do
    study = Studies.get_study!(survey_tool.study_id)

    notify_users_with_role(study, :owner, %{
      title: "New participant for: #{survey_tool.title}"
    })
  end
end
