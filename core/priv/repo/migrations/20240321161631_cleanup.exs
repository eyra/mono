defmodule Core.Repo.Migrations.CleanUp do
  use Ecto.Migration

  def up do
    alter table(:graphite_tools) do
      remove(:max_submissions, :integer)
    end

    execute(
      "ALTER TABLE graphite_tools RENAME CONSTRAINT benchmark_tools_auth_node_id_fkey TO graphite_tools_auth_node_id_fkey;"
    )

    execute(
      "ALTER TABLE tool_refs RENAME CONSTRAINT tool_refs_benchmark_tool_id_fkey TO tool_refs_graphite_tool_id_fkey;"
    )
  end

  def down do
    execute(
      "ALTER TABLE tool_refs RENAME CONSTRAINT tool_refs_graphite_tool_id_fkey TO tool_refs_benchmark_tool_id_fkey;"
    )

    execute(
      "ALTER TABLE graphite_tools RENAME CONSTRAINT graphite_tools_auth_node_id_fkey TO benchmark_tools_auth_node_id_fkey;"
    )

    alter table(:graphite_tools) do
      add(:max_submissions, :integer)
    end
  end
end
