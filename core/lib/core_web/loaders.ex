defmodule CoreWeb.Loaders do
  @moduledoc """
  The loaders for the Link application. They integrate with the GreenLight
  framework.
  """
  import GreenLight.Loaders, only: [defloader: 2]
  alias Core.Survey.Tools

  defloader(:study, &Core.Studies.get_study!/1)
  defloader(:survey_tool, &Core.Survey.Tools.get_survey_tool!/1)
  defloader(:user_profile, &Core.Accounts.get_profile/1)

  def task_loader!(
        %{assigns: %{survey_tool: survey_tool, user: user}},
        _params,
        _as_parent
      ) do
    {:survey_tool_task, Tools.get_task(survey_tool, user)}
  end
end
