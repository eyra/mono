defmodule Systems.Admin.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Admin

  @impl true
  def view_model(Admin.ConfigPage, model, assigns) do
    Admin.ConfigPageBuilder.view_model(model, assigns)
  end

  def view_model(Admin.ActionsView, model, assigns) do
    Admin.ActionsViewBuilder.view_model(model, assigns)
  end

  def view_model(Admin.AccountView, model, assigns) do
    Admin.AccountViewBuilder.view_model(model, assigns)
  end

  def view_model(Admin.OrgView, model, assigns) do
    Admin.OrgViewBuilder.view_model(model, assigns)
  end

  def view_model(Admin.SystemView, model, assigns) do
    Admin.SystemViewBuilder.view_model(model, assigns)
  end
end
