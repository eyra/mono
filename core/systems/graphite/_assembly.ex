defmodule Systems.Graphite.Assembly do
  use Core, :auth
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Repo
  alias Ecto.Changeset
  alias Ecto.Multi

  alias Frameworks.Signal

  alias Systems.Graphite
  alias Systems.Project
  alias Systems.Assignment

  def create_leaderboard(%Graphite.ToolModel{} = tool, name) do
    if challenge = Assignment.Public.get_by_tool(tool) do
      create_leaderboard(challenge, tool, name)
    else
      raise "Can not create leaderboard for tool without Benchmark Challenge"
    end
  end

  def create_leaderboard(
        %Assignment.Model{special: :benchmark_challenge} = challenge,
        tool,
        name
      ) do
    project_node =
      challenge
      |> Project.Public.get_item_by()
      |> Project.Public.get_node_by_item!([:auth_node])

    leaderboard_name = get_leaderboard_name(name, project_node)
    project_item = prepare_leaderboard_project_item(project_node, tool, leaderboard_name)

    Multi.new()
    |> Multi.insert(:project_item, project_item)
    |> Signal.Public.multi_dispatch({:project_item, :inserted})
    |> Repo.transaction()
  end

  def get_leaderboard_name(nil, project_node) do
    Project.Public.new_item_name(
      project_node,
      dgettext("eyra-graphite", "leaderboard.default.name")
    )
  end

  def get_leaderboard_name(name, project_node) when is_binary(name) do
    case name do
      "" -> get_leaderboard_name(nil, project_node)
      name -> name
    end
  end

  defp prepare_leaderboard_project_item(
         %{id: project_node_id, project_path: project_path} = project_node,
         %{auth_node: tool_auth_node} = tool,
         name
       ) do
    leaderboard_auth_node = auth_module().prepare_node(tool_auth_node)

    Project.Public.prepare_item(
      %{name: name, project_path: project_path ++ [project_node_id]},
      %{
        name: name,
        status: :concept,
        visibility: :private,
        allow_anonymous: false,
        metrics: []
      }
      |> Graphite.Public.prepare_leaderboard(leaderboard_auth_node)
      |> Changeset.put_assoc(:tool, tool)
    )
    |> Changeset.put_assoc(:node, project_node)
  end
end
