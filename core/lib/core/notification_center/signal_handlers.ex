defmodule Core.NotificationCenter.SignalHandlers do
  use Core.Signals.Handlers
  import Core.NotificationCenter, only: [notify_users_with_role: 3]

  @impl true
  def dispatch(:participant_applied, %{survey_tool: survey_tool}) do
    notify_users_with_role(survey_tool, :owner, %{
      title: "New application for: #{survey_tool.title}"
    })
  end
end
