defmodule Systems.Assignment.FinishRaceTest do
  @moduledoc """
  Proves that when a member's last two required tasks complete in overlapping
  transactions, exactly one of them finishes the member.

  Runs outside the SQL sandbox (`:auto` mode, deleting the rows it added afterwards):
  the two completions have to run on *separate* database connections,
  which a single shared sandbox connection cannot express. The test holds a lock on
  `monitor_events`, which each completion writes after updating its task and before
  checking whether the member is finished, so both are in the middle of their
  transaction when it lets them go.
  """
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Mica.Repo

  alias Ecto.Adapters.SQL.Sandbox
  alias Mica.Repo
  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  @contention_timeout 10_000
  @completion_timeout 30_000

  setup do
    Sandbox.mode(Repo, :auto)
    snapshot = snapshot()
    on_exit(fn -> reset_sandbox(snapshot) end)

    assignment =
      Assignment.Factories.create_template_assignment(:data_donation, [
        :manual,
        :donate,
        :questionnaire
      ])

    affiliate =
      Repo.update!(
        Ecto.Changeset.change(assignment.affiliate, callback_url: "https://panel.example/cb")
      )

    %{user: user} =
      Mica.Factories.insert!(:affiliate_user, %{affiliate: affiliate, identifier: "p1"})

    {:ok, %{member: member}} = Assignment.Public.add_participant!(assignment, user)

    tasks =
      Map.new(Workflow.Public.list_items(assignment.workflow_id, [:tool_ref]), fn item ->
        identifier = Assignment.Private.task_identifier(assignment, item, member)
        {item.tool_ref.special, Crew.Public.create_task!(assignment.crew, [user], identifier)}
      end)

    complete_overlapping([tasks.donate, tasks.questionnaire])

    %{assignment: assignment, user: user}
  end

  test "one of them completes the participation", %{assignment: assignment, user: user} do
    assert %{completed_at: %NaiveDateTime{}} =
             Assignment.Public.get_participation(assignment, user)
  end

  test "one of them queues assignment_finished", %{user: user} do
    assert ["assignment_finished"] = progress_events(user, "assignment_finished")
  end

  defp complete_overlapping(tasks) do
    # credo:disable-for-next-line Credo.Check.Warning.NoRepoTransaction
    {:ok, completions} = Repo.transaction(fn -> complete_while_locked(tasks) end)

    for result <- Task.await_many(completions, @completion_timeout) do
      assert {:ok, _} = result
    end
  end

  defp complete_while_locked(tasks) do
    Repo.query!("LOCK TABLE monitor_events IN EXCLUSIVE MODE")
    completions = Enum.map(tasks, &Task.async(fn -> Crew.Public.complete_task(&1) end))
    await_lock_waiters(length(completions))
    completions
  end

  defp await_lock_waiters(count) do
    await_lock_waiters(count, System.monotonic_time(:millisecond) + @contention_timeout)
  end

  defp await_lock_waiters(count, deadline) do
    cond do
      lock_waiter_count() >= count -> :ok
      System.monotonic_time(:millisecond) > deadline -> flunk("expected #{count} lock waiters")
      true -> retry_lock_waiters(count, deadline)
    end
  end

  defp retry_lock_waiters(count, deadline) do
    Process.sleep(25)
    await_lock_waiters(count, deadline)
  end

  defp lock_waiter_count do
    %{rows: [[count]]} =
      Repo.query!("""
      SELECT count(*) FROM pg_stat_activity
      WHERE datname = current_database()
        AND wait_event_type = 'Lock'
        AND pid <> pg_backend_pid()
      """)

    count
  end

  defp progress_events(%{id: user_id}, progress) do
    for %{args: %{"user_id" => ^user_id, "event" => %{"progress" => ^progress}}} <-
          all_enqueued(worker: Affiliate.CallbackWorker),
        do: progress
  end

  # What each table holds before the test: the highest id, or for a table without an id
  # column its rows, so afterwards exactly the rows the test added can be deleted, also
  # from tables the migrations or seeds already filled.
  defp snapshot do
    %{rows: rows} =
      Repo.query!("""
      SELECT t.relname, EXISTS (
        SELECT 1 FROM pg_attribute a
        WHERE a.attrelid = t.oid AND a.attname = 'id' AND NOT a.attisdropped
      )
      FROM pg_class t
      WHERE t.relkind = 'r' AND t.relnamespace = 'public'::regnamespace
        AND t.relname <> 'schema_migrations'
      """)

    Map.new(rows, fn
      [table, true] -> {table, {:max_id, max_id(table)}}
      [table, false] -> {table, {:rows, rows(table)}}
    end)
  end

  defp max_id(table) do
    %{rows: [[max_id]]} = Repo.query!(~s|SELECT coalesce(max(id), 0) FROM "#{table}"|)
    max_id
  end

  defp rows(table) do
    %{rows: rows} = Repo.query!(~s|SELECT to_jsonb(t) FROM "#{table}" AS t|)
    List.flatten(rows)
  end

  # Deletes the rows this test added, so later sandboxed tests start from the same data.
  # Foreign key triggers are off for this transaction only, so the order doesn't matter.
  defp reset_sandbox(snapshot) do
    # credo:disable-for-next-line Credo.Check.Warning.NoRepoTransaction
    {:ok, _} = Repo.transaction(fn -> delete_added_rows(snapshot) end)
  after
    Sandbox.mode(Repo, :manual)
  end

  defp delete_added_rows(snapshot) do
    Repo.query!("SET LOCAL session_replication_role = replica")

    Enum.each(snapshot, fn
      {table, {:max_id, max_id}} ->
        Repo.query!(~s|DELETE FROM "#{table}" WHERE id > $1|, [max_id])

      {table, {:rows, rows}} ->
        Repo.query!(~s|DELETE FROM "#{table}" AS t WHERE NOT (to_jsonb(t) = ANY($1::jsonb[]))|, [
          rows
        ])
    end)
  end
end
