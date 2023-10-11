defmodule Systems.Promotion.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Promotion

  @impl true
  def view_model(%Promotion.Model{director: director} = promotion, page, assigns) do
    Frameworks.Concept.System.presenter(director).view_model(promotion, page, assigns)
  end
end
