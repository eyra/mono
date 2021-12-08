defmodule Systems.Assignment.ContextTest do
  use Core.DataCase
  import Systems.NextAction.TestHelper

  describe "assignments" do
    alias Core.Accounts

    alias Systems.{
      Assignment,
      Crew
    }

    alias Core.Factories
    alias CoreWeb.UI.Timestamp

    test "open?/1 true, with 1 expired pending task" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :pending, true)

      assert Assignment.Context.open?(assignment)
    end

    test "open?/1 true, with 1 expired pending task and 1 completed task" do
      %{crew: crew} = assignment = create_assignment(31, 2)
      _task = create_task(crew, :completed, false)
      _task = create_task(crew, :pending, true)

      assert Assignment.Context.open?(assignment)
    end

    test "open?/1 true, with 0 tasks" do
      assignment = create_assignment(31, 1)

      assert Assignment.Context.open?(assignment)
    end

    test "open?/1 false, with 1 pending task left" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :pending, false)

      assert not Assignment.Context.open?(assignment)
    end

    test "open?/1 false, with completed tasks" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :completed, false)

      assert not Assignment.Context.open?(assignment)
    end

    test "mark_expired?/1 force=false, marked 1 expired task" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task1 = create_task(crew, :pending, false, 31)
      task2 = create_task(crew, :pending, false, 20)
      task3 = create_task(crew, :completed, false, 60)

      Assignment.Context.mark_expired_debug(assignment, false)

      assert %{expired: true} = Crew.Context.get_member!(task1.member_id)
      assert %{expired: false} = Crew.Context.get_member!(task2.member_id)
      assert %{expired: false} = Crew.Context.get_member!(task3.member_id)

      assert %{expired: true} = Crew.Context.get_task!(task1.id)
      assert %{expired: false} = Crew.Context.get_task!(task2.id)
      assert %{expired: false} = Crew.Context.get_task!(task3.id)
    end

    test "apply_expired?/1 force=true, marked all pending tasks" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task1 = create_task(crew, :pending, false, 31)
      task2 = create_task(crew, :pending, false, 20)
      task3 = create_task(crew, :completed, false, 60)

      Assignment.Context.mark_expired_debug(assignment, true)

      assert %{expired: true} = Crew.Context.get_member!(task1.member_id)
      assert %{expired: true} = Crew.Context.get_member!(task2.member_id)
      assert %{expired: false} = Crew.Context.get_member!(task3.member_id)

      assert %{expired: true} = Crew.Context.get_task!(task1.id)
      assert %{expired: true} = Crew.Context.get_task!(task2.id)
      assert %{expired: false} = Crew.Context.get_task!(task3.id)
    end

    test "apply_member!/2 re-uses expired member" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task = create_task(crew, :pending, false, 31)

      Assignment.Context.mark_expired_debug(assignment, false)

      assert %{expired: true} = Crew.Context.get_member!(task.member_id)
      assert %{expired: true} = Crew.Context.get_task!(task.id)

      member = Crew.Context.get_member!(task.member_id)
      user = Accounts.get_user!(member.user_id)

      Assignment.Context.apply_member(assignment, user)

      assert %{expired: false} = Crew.Context.get_member!(task.member_id)
      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "open_spot_count/3 with 1 expired spot" do
      %{crew: crew} = assignment = create_assignment(10, 3)
      _task1 = create_task(crew, :pending, false, 10)
      _task2 = create_task(crew, :pending, true, 31)
      _task3 = create_task(crew, :completed, false)

      assert Assignment.Context.open_spot_count(assignment) == 1
    end

    test "open_spot_count/3 with 1 expired and one open spot" do
      %{crew: crew} = assignment = create_assignment(10, 4)
      _task1 = create_task(crew, :pending, false, 10)
      _task2 = create_task(crew, :pending, true, 31)
      _task3 = create_task(crew, :completed, false)

      assert Assignment.Context.open_spot_count(assignment) == 2
    end

    test "open_spot_count/3 with all open spots" do
      assignment = create_assignment(31, 3)
      assert Assignment.Context.open_spot_count(assignment) == 3
    end

    test "next_action (Assignment.CheckRejection) after rejection of task" do
      %{crew: crew} = create_assignment(31, 3)
      %{id: task_id, member: %{user: user}} = create_task(crew, :pending, false, 10)

      Crew.Context.reject_task(task_id, %{category: :other, message: "rejected"})

      url_resolver = fn target, _ ->
        case target do
          Systems.Assignment.LandingPage -> "/assignment"
        end
      end

      assert_next_action(user, url_resolver, "/assignment")
    end

    test "next_action cleared after acceptence of task" do
      %{crew: crew} = create_assignment(31, 3)
      %{id: task_id, member: %{user: user}} = create_task(crew, :pending, false, 10)

      Crew.Context.reject_task(task_id, %{category: :other, message: "rejected"})
      Crew.Context.accept_task(task_id)

      url_resolver = fn target, _ ->
        case target do
          Systems.Assignment.LandingPage -> "/assignment"
        end
      end

      refute_next_action(user, url_resolver, "/assignment")
    end

    defp create_assignment(duration, subject_count) do
      crew = Factories.insert!(:crew)

      survey_tool =
        Factories.insert!(:survey_tool, %{
          survey_url: "http://eyra.co/survey/123"
        })

      experiment =
        Factories.insert!(:experiment, %{
          survey_tool: survey_tool,
          duration: Integer.to_string(duration),
          subject_count: subject_count
        })

      Factories.insert!(:assignment, %{experiment: experiment, crew: crew})
    end

    defp create_task(crew, status, expired, minutes_ago \\ 31) when is_boolean(expired) do
      updated_at = Timestamp.naive_from_now(minutes_ago * -1)

      user = Factories.insert!(:member)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      _task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: status,
          expired: expired,
          updated_at: updated_at
        })
    end
  end
end
