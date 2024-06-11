defmodule Systems.Project.OverviewPageBuilder do
  alias Frameworks.Utility.ViewModelBuilder

  import CoreWeb.Gettext

  alias Systems.Project

  def view_model(
        user,
        assigns
      ) do
    projects = projects(user)
    cards = cards(projects, assigns)

    %{
      title: dgettext("eyra-project", "overview.title"),
      projects: projects,
      cards: cards,
      active_menu_item: :projects
    }
  end

  defp projects(user) do
    preload = Project.Model.preload_graph(:down)
    Project.Public.list_owned_projects(user, preload: preload)
  end

  defp cards(projects, assigns) do
    Enum.map(
      projects,
      &ViewModelBuilder.view_model(&1, {Systems.Project.OverviewPage, :card}, assigns)
    )
  end
end
