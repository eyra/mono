defmodule Systems.Admin.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Admin

  @impl true
  def view_model(Admin.ConfigPage, model, assigns) do
    Admin.ConfigPageBuilder.view_model(model, assigns)
  end
end
