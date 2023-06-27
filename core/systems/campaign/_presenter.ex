defmodule Systems.Campaign.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  def update(%Campaign.Model{} = campaign, id, page) do
    Signal.Public.dispatch!(%{page: page}, %{id: id, model: campaign})
    campaign
  end

  # View Model By ID

  @impl true
  def view_model(id, Campaign.ContentPage = page, assigns) when is_number(id) do
    Campaign.Public.get!(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(id, Promotion.LandingPage = page, assigns) when is_number(id) do
    Campaign.Public.get_by_promotion(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(id, Assignment.CallbackPage = page, assigns) when is_number(id) do
    Campaign.Public.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(id, Assignment.LandingPage = page, assigns) when is_number(id) do
    Campaign.Public.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, assigns)
  end

  # View Model By Campaign

  @impl true
  def view_model(%Campaign.Model{} = campaign, page, assigns) do
    builder(page).view_model(campaign, assigns)
  end

  defp builder(Campaign.ContentPage), do: Campaign.Builders.CampaignContentPage
  defp builder(Assignment.CallbackPage), do: Campaign.Builders.AssignmentCallbackPage
  defp builder(Assignment.LandingPage), do: Campaign.Builders.AssignmentLandingPage
  defp builder(Promotion.LandingPage), do: Campaign.Builders.PromotionLandingPage
end
