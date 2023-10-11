defmodule Systems.Pool.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Pool

  @impl true
  def view_model(%Pool.Model{director: director} = pool, page, assigns) do
    Frameworks.Concept.System.presenter(director).view_model(pool, page, assigns)
  end
end
