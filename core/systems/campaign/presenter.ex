defmodule Systems.Campaign.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  @impl true
  def view_model(%Campaign.Model{} = campaign, page, user, url_resolver) do
    campaign
    |> Builder.view_model(page, user, url_resolver)
  end

  @impl true
  def view_model(id, Promotion.LandingPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotion(id, Campaign.Model.preload_graph(:full))
    |> Builder.view_model(page, user, url_resolver)
  end

  @impl true
  def view_model(id, Assignment.LandingPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> Builder.view_model(page, user, url_resolver)
  end

  @impl true
  def view_model(id, Assignment.CallbackPage = page, user, url_resolver) when is_number(id) do
    Campaign.Context.get_by_promotable(id, Campaign.Model.preload_graph(:full))
    |> Builder.view_model(page, user, url_resolver)
  end

  def update(%Campaign.Model{} = campaign, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{id: id, model: campaign})
    campaign
  end
end
