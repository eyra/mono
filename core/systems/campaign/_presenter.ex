defmodule Systems.Campaign.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  def update(%Campaign.Model{} = campaign, id, page) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: campaign})
    campaign
  end

  @impl true
  def view_model(%Assignment.Model{} = assignment, page, assigns) do
    Campaign.Public.get_by_promotable(assignment, Campaign.Model.preload_graph(:down))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(%Promotion.Model{} = promotion, page, assigns) do
    Campaign.Public.get_by_promotion(promotion, Campaign.Model.preload_graph(:down))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(%Campaign.Model{} = campaign, page, assigns) do
    builder(page).view_model(campaign, assigns)
  end

  defp builder(Campaign.ContentPage), do: Campaign.Builders.CampaignContentPage
  defp builder(Alliance.CallbackPage), do: Campaign.Builders.AssignmentCallbackPage
  defp builder(Assignment.LandingPage), do: Campaign.Builders.AssignmentLandingPage
  defp builder(Promotion.LandingPage), do: Campaign.Builders.PromotionLandingPage
end
