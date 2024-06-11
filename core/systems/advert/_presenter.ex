defmodule Systems.Advert.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Advert,
    Promotion,
    Assignment
  }

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    advert = Advert.Public.get_by_assignment(assignment, Advert.Model.preload_graph(:down))
    view_model(page, advert, assigns)
  end

  @impl true
  def view_model(page, %Promotion.Model{} = promotion, assigns) do
    advert = Advert.Public.get_by_promotion(promotion, Advert.Model.preload_graph(:down))
    view_model(page, advert, assigns)
  end

  @impl true
  def view_model(page, %Advert.Model{} = advert, assigns) do
    builder(page).view_model(advert, assigns)
  end

  defp builder(Advert.ContentPage), do: Advert.ContentPageBuilder
  defp builder(Alliance.CallbackPage), do: Advert.Builders.AssignmentCallbackPage
  defp builder(Promotion.LandingPage), do: Advert.PromotionLandingPageBuilder
end
