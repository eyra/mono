defmodule Systems.Pool.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Pool

  @impl true
  def view_model(page, %Pool.Model{director: director} = pool, assigns) do
    Frameworks.Concept.System.presenter(director).view_model(page, pool, assigns)
  end
end
