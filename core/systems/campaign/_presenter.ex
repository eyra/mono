defmodule Systems.Campaign.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    campaign = Campaign.Public.get_by_promotable(assignment, Campaign.Model.preload_graph(:down))
    view_model(page, campaign, assigns)
  end

  @impl true
  def view_model(page, %Promotion.Model{} = promotion, assigns) do
    campaign = Campaign.Public.get_by_promotion(promotion, Campaign.Model.preload_graph(:down))
    view_model(page, campaign, assigns)
  end

  @impl true
  def view_model(page, %Campaign.Model{} = campaign, assigns) do
    builder(page).view_model(campaign, assigns)
  end

  defp builder(Campaign.ContentPage), do: Campaign.Builders.CampaignContentPage
  defp builder(Alliance.CallbackPage), do: Campaign.Builders.AssignmentCallbackPage
  defp builder(Assignment.LandingPage), do: Campaign.Builders.AssignmentLandingPage
  defp builder(Promotion.LandingPage), do: Campaign.Builders.PromotionLandingPage
end
