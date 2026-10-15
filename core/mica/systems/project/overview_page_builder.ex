defmodule Systems.Project.OverviewPageBuilder do
  alias Frameworks.Utility.ViewModelBuilder

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.NextAction
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
      next_best_action: NextAction.Public.next_best_action(user),
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
