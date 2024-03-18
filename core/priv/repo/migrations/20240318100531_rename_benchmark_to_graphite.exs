defmodule Core.Repo.Migrations.RenameBenchmarkToGraphite do
  use Ecto.Migration

  def up do
    rename(table(:tool_refs), :benchmark_tool_id, to: :graphite_tool_id)

    rename(table(:benchmark_leaderboards), to: table(:graphite_leaderboards))
    execute("ALTER INDEX benchmark_leaderboards_pkey RENAME TO graphite_leaderboards_pkey")

    execute(
      "ALTER INDEX benchmark_leaderboards_name_version_index RENAME TO graphite_leaderboards_name_version_index"
    )

    rename(table(:benchmark_scores), to: table(:graphite_scores))
    execute("ALTER INDEX benchmark_scores_pkey RENAME TO graphite_scores_pkey")

    rename(table(:benchmark_submissions), to: table(:graphite_submissions))
    execute("ALTER INDEX benchmark_submissions_pkey RENAME TO graphite_submissions_pkey")

    rename(table(:benchmark_tools), to: table(:graphite_tools))
    execute("ALTER INDEX benchmark_tools_pkey RENAME TO graphite_tools_pkey")
  end

  def down do
    rename(table(:tool_refs), :graphite_tool_id, to: :benchmark_tool_id)

    rename(table(:graphite_leaderboards), to: table(:benchmark_leaderboards))
    execute("ALTER INDEX graphite_leaderboards_pkey RENAME TO benchmark_leaderboards_pkey")

    execute(
      "ALTER INDEX graphite_leaderboards_name_version_index RENAME TO benchmark_leaderboards_name_version_index"
    )

    rename(table(:graphite_scores), to: table(:benchmark_scores))
    execute("ALTER INDEX graphite_scores_pkey RENAME TO benchmark_scores_pkey")

    rename(table(:graphite_submissions), to: table(:benchmark_submissions))
    execute("ALTER INDEX graphite_submissions_pkey RENAME TO benchmark_submissions_pkey")

    rename(table(:graphite_tools), to: table(:benchmark_tools))
    execute("ALTER INDEX graphite_tools_pkey RENAME TO benchmark_tools_pkey")
  end
end
