defmodule LinkWeb.Loaders do
  @moduledoc """
  The loaders for the Link application. They integrate with the GreenLight
  framework.
  """
  import GreenLight.Loaders, only: [defloader: 2]

  defloader(:study, &Link.Studies.get_study!/1)
  defloader(:survey_tool, &Link.SurveyTools.get_survey_tool!/1)
  defloader(:user_profile, &Link.Users.get_profile/1)
end
