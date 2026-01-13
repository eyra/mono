defmodule Systems.Org.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Org

  @impl true
  def view_model(Org.ContentPage, model, assigns) do
    Org.ContentPageBuilder.view_model(model, assigns)
  end

  def view_model(Org.NodeView, model, assigns) do
    Org.NodeViewBuilder.view_model(model, assigns)
  end

  def view_model(Org.UserView, model, assigns) do
    Org.UserViewBuilder.view_model(model, assigns)
  end

  def view_model(Org.OwnersView, model, assigns) do
    Org.OwnersViewBuilder.view_model(model, assigns)
  end

  def view_model(Org.AdminsModalView, model, assigns) do
    Org.AdminsModalViewBuilder.view_model(model, assigns)
  end

  def view_model(Org.ArchiveModalView, model, assigns) do
    Org.ArchiveModalViewBuilder.view_model(model, assigns)
  end
end
