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

  def view_model(Org.MemberView, model, assigns) do
    Org.MemberViewBuilder.view_model(model, assigns)
  end

  def view_model(Org.PoolsView, model, assigns) do
    Org.PoolsViewBuilder.view_model(model, assigns)
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
