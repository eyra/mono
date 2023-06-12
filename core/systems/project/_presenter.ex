defmodule Systems.Project.Presenter do
  use Systems.Presenter

  alias Systems.{
    Project
  }

  @impl true
  def view_model(id, Project.ContentPage = page, assigns, url_resolver) when is_number(id) do
    Project.Public.get!(id, Project.Model.preload_graph(:full))
    |> view_model(page, assigns, url_resolver)
  end

  @impl true
  def view_model(%Project.Model{} = study, page, assigns, _url_resolver) do
    builder(page).view_model(study, assigns)
  end

  defp builder(Project.ContentPage), do: Project.ContentPageBuilder
end
