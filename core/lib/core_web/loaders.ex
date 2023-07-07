defmodule CoreWeb.Loaders do
  @moduledoc """
  The loaders for the Link application. They integrate with the GreenLight
  framework.
  """
  import Frameworks.GreenLight.Loaders, only: [defloader: 2]

  defloader(:campaign, &Systems.Campaign.Public.get!/1)
  defloader(:promotion, &Systems.Promotion.Public.get!/1)
  defloader(:assignment, &Systems.Assignment.Public.get!/1)
  defloader(:questionnaire_tool, &Systems.Questionnaire.Public.get_questionnaire_tool!/1)
  defloader(:user_profile, &Core.Accounts.get_profile/1)
end
