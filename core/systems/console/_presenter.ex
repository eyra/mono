defmodule Systems.Console.Presenter do
  @behaviour Frameworks.Concept.Presenter

  @impl true
  def view_model(Systems.Console.Page, user, assigns) do
    Systems.Console.PageBuilder.view_model(user, assigns)
  end
end
