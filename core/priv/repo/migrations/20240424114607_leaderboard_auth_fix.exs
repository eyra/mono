defmodule Core.Repo.Migrations.LeaderboardAuthFix do
  use Ecto.Migration

  require Logger

  import Ecto.Adapters.SQL

  def up do
    migrate_graphite_tools()
  end

  def down do
  end

  defp migrate_graphite_tools() do
    query_all(:graphite_tools, "id,auth_node_id")
    |> Enum.each(&migrate_graphite_tool(&1))
  end

  defp migrate_graphite_tool([tool_id, tool_auth_node_id]) do
    "Migrate tool #{tool_id}" |> Logger.notice()

    # Fix for https://github.com/eyra/mono/issues/778
    # See previous migration: Core.Repo.Migrations.LeaderboardAuth
    # before: "id = #{tool_ref_id}"
    # after: "tool_ref_id = #{tool_ref_id}"

    with {:ok, tool_ref_id} <- query_id(:tool_refs, "id", "graphite_tool_id = #{tool_id}"),
         {:ok, workflow_id} <-
           query_id(:workflow_items, "workflow_id", "tool_ref_id = #{tool_ref_id}"),
         {:ok, workflow_auth_node_id} <-
           query_id(:workflows, "auth_node_id", "id = #{workflow_id}") do
      "Link tool #{tool_id} to workflow #{workflow_id}" |> Logger.notice()
      update(:authorization_nodes, tool_auth_node_id, :parent_id, workflow_auth_node_id)
      flush()
    end
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
end
