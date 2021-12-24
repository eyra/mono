defmodule CoreWeb.Loaders do
  @moduledoc """
  The loaders for the Link application. They integrate with the GreenLight
  framework.
  """
  import Frameworks.GreenLight.Loaders, only: [defloader: 2]

  defloader(:campaign, &Systems.Campaign.Context.get!/1)
  defloader(:promotion, &Systems.Promotion.Context.get!/1)
  defloader(:assignment, &Systems.Assignment.Context.get!/1)
  defloader(:survey_tool, &Systems.Survey.Context.get_survey_tool!/1)
  defloader(:user_profile, &Core.Accounts.get_profile/1)
end
