defmodule Systems.Pool.Presenter do
  use Frameworks.Concept.Presenter

  @impl true
  def view_model(page, %Systems.Pool.Model{} = pool, assigns) do
    builder(page).view_model(pool, assigns)
  end
end
