defmodule Systems.Assignment.FinishRaceTest do
  @moduledoc """
  Proves that when a member's last two required tasks complete in overlapping
  transactions, exactly one of them finishes the member.

  Runs outside the SQL sandbox (`:auto` mode, truncating the tables it filled
  afterwards): the two completions have to run on *separate* database connections,
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
    empty_tables = empty_tables()
    on_exit(fn -> reset_sandbox(empty_tables) end)

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

  defp empty_tables do
    %{rows: rows} =
      Repo.query!("""
      SELECT relname FROM pg_class
      WHERE relkind = 'r' AND relnamespace = 'public'::regnamespace
        AND relname <> 'schema_migrations'
      """)

    Enum.filter(List.flatten(rows), &(row_count(&1) == 0))
  end

  defp row_count(table) do
    %{rows: [[count]]} = Repo.query!(~s|SELECT count(*) FROM "#{table}"|)
    count
  end

  # Empties the tables this test filled, so later sandboxed tests start from the same data
  defp reset_sandbox(empty_tables) do
    filled = Enum.filter(empty_tables, &(row_count(&1) > 0))

    unless filled == [] do
      Repo.query!("TRUNCATE #{Enum.map_join(filled, ", ", &~s|"#{&1}"|)} CASCADE")
    end
  after
    Sandbox.mode(Repo, :manual)
  end
end
