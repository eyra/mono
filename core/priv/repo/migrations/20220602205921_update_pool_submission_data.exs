defmodule Core.Repo.Migrations.UpdatePoolSubmissionData do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_submissions()
  end

  def down do
  end

  defp migrate_submissions() do
    tools =
      query(
        Core.Repo,
        "
    SELECT ps.id, ps.status, cr.id
    FROM pool_submissions as ps
    INNER JOIN campaigns as c ON c.promotion_id = ps.promotion_id
    INNER JOIN assignments as a ON a.id = c.promotable_assignment_id
    INNER JOIN experiments as e ON e.id = a.assignable_experiment_id
    INNER JOIN crews as cr ON cr.id = a.crew_id
    GROUP BY ps.id, ps.status, cr.id
    ORDER BY ps.id;
    "
      )

    migrate_submissions(tools)
  end

  defp migrate_submissions({:ok, %{rows: []}}) do
    IO.puts("No submissions found to migrate")
  end

  defp migrate_submissions({:ok, %{rows: submissions}}) do
    migrate_submissions(submissions)
  end

  defp migrate_submissions([]), do: :noop

  defp migrate_submissions([h | t]) do
    migrate_submission(h)
    migrate_submissions(t)
  end

  defp migrate_submission([id, "idle", crew_id]) do
    {:ok, %{rows: [[count]]}} =
      query(Core.Repo, "SELECT count(*) FROM crew_tasks where crew_id = #{crew_id};")

    if count > 0 do
      update(:pool_submissions, id, :submitted_at, now())
      update(:pool_submissions, id, :accepted_at, now())
    end
  end

  defp migrate_submission([id, "submitted", _]) do
    update(:pool_submissions, id, :submitted_at, now())
  end

  defp migrate_submission([id, "accepted", _]) do
    update(:pool_submissions, id, :submitted_at, now())
    update(:pool_submissions, id, :accepted_at, now())
  end

  defp migrate_submission([id, "completed", _]) do
    update(:pool_submissions, id, :submitted_at, now())
    update(:pool_submissions, id, :accepted_at, now())
  end

  def update(table, id, field, value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end

  def now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end
end
