defmodule Systems.Promotion.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Promotion

  @impl true
  def view_model(page, %Promotion.Model{director: director} = promotion, assigns) do
    presenter = Frameworks.Concept.System.presenter(director)
    presenter.view_model(page, promotion, assigns)
  end
end
