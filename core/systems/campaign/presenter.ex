defmodule Systems.Campaign.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  def update(%Campaign.Model{} = campaign, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{id: id, model: campaign})
    campaign
  end

  # View Model By ID

  @impl true
  def view_model(id, Promotion.LandingPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotion(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, user, url_resolver)
  end

  @impl true
  def view_model(id, Assignment.CallbackPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, user, url_resolver)
  end

  @impl true
  def view_model(id, Assignment.LandingPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> view_model(page, user, url_resolver)
  end

  # View Model By Campaign

  @impl true
  def view_model(%Campaign.Model{} = campaign, page, user, url_resolver) do
    builder(page).view_model(campaign, user, url_resolver)
  end

  defp builder(Assignment.CallbackPage), do: Campaign.Builders.AssignmentCallbackPage
  defp builder(Assignment.LandingPage), do: Campaign.Builders.AssignmentLandingPage
  defp builder(Promotion.LandingPage), do: Campaign.Builders.PromotionLandingPage
end
