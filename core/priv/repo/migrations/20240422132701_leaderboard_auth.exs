defmodule Core.Repo.Migrations.LeaderboardAuth do
  use Ecto.Migration

  require Logger

  import Ecto.Adapters.SQL

  def up do
    alter table(:workflows) do
      add(:auth_node_id, references(:authorization_nodes))
    end

    migrate_crews()
    migrate_workflows()
    migrate_graphite_tools()
    migrate_leaderboards()
  end

  def down do
    alter table(:workflows) do
      remove(:auth_node_id)
    end
  end

  defp migrate_crews() do
    query_all(:assignments, "id,auth_node_id,crew_id")
    |> Enum.each(&migrate_crew(&1))
  end

  defp migrate_crew([assignment_id, assignment_auth_node_id, crew_id]) do
    "Migrate crew #{crew_id}" |> Logger.notice()

    if {:ok, crew_auth_node_id} = query_id(:crews, "auth_node_id", "id = #{crew_id}") do
      "Link crew #{crew_id} to assignment #{assignment_id}" |> Logger.notice()
      update(:authorization_nodes, crew_auth_node_id, :parent_id, assignment_auth_node_id)
      flush()
    end
  end

  defp migrate_workflows() do
    query_all(:workflows, "id")
    |> Enum.each(&migrate_workflow(&1))
  end

  defp migrate_workflow([id]) do
    "Migrate workflow #{id}" |> Logger.notice()
    {:ok, workflow_auth_node_id} = create_auth_node(:workflows, id)

    with {:ok, crew_id} <- query_id(:assignments, "crew_id", "workflow_id = #{id}"),
         {:ok, crew_auth_node_id} <- query_id(:crews, "auth_node_id", "id = #{crew_id}") do
      "Link workflow #{id} to crew #{crew_id}" |> Logger.notice()
      update(:authorization_nodes, workflow_auth_node_id, :parent_id, crew_auth_node_id)
    end

    flush()
  end

  defp migrate_graphite_tools() do
    query_all(:graphite_tools, "id,auth_node_id")
    |> Enum.each(&migrate_graphite_tool(&1))
  end

  defp migrate_graphite_tool([tool_id, tool_auth_node_id]) do
    "Migrate tool #{tool_id}" |> Logger.notice()

    with {:ok, tool_ref_id} <- query_id(:tool_refs, "id", "graphite_tool_id = #{tool_id}"),
         {:ok, workflow_id} <- query_id(:workflow_items, "workflow_id", "id = #{tool_ref_id}"),
         {:ok, workflow_auth_node_id} <-
           query_id(:workflows, "auth_node_id", "id = #{workflow_id}") do
      "Link tool #{tool_id} to workflow #{workflow_id}" |> Logger.notice()
      update(:authorization_nodes, tool_auth_node_id, :parent_id, workflow_auth_node_id)
      flush()
    end
  end

  defp migrate_leaderboards() do
    query_all(:graphite_leaderboards, "id,auth_node_id,tool_id")
    |> Enum.each(&migrate_leaderboard(&1))
  end

  defp migrate_leaderboard([leaderboard_id, leaderboard_auth_node_id, graphite_tool_id]) do
    "Migrate leaderboard #{leaderboard_id}" |> Logger.notice()

    if {:ok, graphite_tool_auth_node_id} =
         query_id(:graphite_tools, "auth_node_id", "id = #{graphite_tool_id}") do
      "Link leaderboard #{leaderboard_id} to graphite_tool #{graphite_tool_id}" |> Logger.notice()

      update(
        :authorization_nodes,
        leaderboard_auth_node_id,
        :parent_id,
        graphite_tool_auth_node_id
      )

      flush()
    end
  end

  defp create_auth_node(table, id) do
    execute("""
    INSERT INTO authorization_nodes (inserted_at, updated_at)
    VALUES ('#{now()}', '#{now()}');
    """)

    execute("""
    UPDATE #{table} SET auth_node_id = CURRVAL('authorization_nodes_id_seq') WHERE id = '#{id}' ;
    """)

    flush()

    query_id(table, :auth_node_id, "id = #{id}")
  end

  defp query_all(table, fields) do
    {:ok, %{rows: rows}} = query(Core.Repo, "SELECT #{fields} FROM #{table}")
    rows
  end

  def query_id(table, field, where) do
    case query(Core.Repo, "SELECT #{field} FROM #{table} WHERE #{where}") do
      {:ok, %{rows: [[value] | _]}} -> {:ok, value}
      _ -> :error
    end
  end

  defp update(table, id, field, value) when is_integer(value) do
    execute("""
    UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
    """)
  end

  defp now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end
end
