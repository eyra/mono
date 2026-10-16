defmodule Systems.Storage.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Storage

  @impl true
  def view_model(Storage.EndpointContentPage, node, assigns) do
    Storage.EndpointContentPageBuilder.view_model(node, assigns)
  end
end
