defmodule Systems.Assignment.PublicTest do
  use Core.DataCase
  import Systems.NextAction.TestHelper

  describe "assignments" do
    alias Core.Accounts

    alias Systems.{
      Assignment,
      Crew,
      Budget
    }

    alias Core.Factories
    alias CoreWeb.UI.Timestamp

    test "has_open_spots?/1 true, with 1 expired pending task" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :pending, true)

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 true, with 1 expired pending task and 1 completed task" do
      %{crew: crew} = assignment = create_assignment(31, 2)
      _task = create_task(crew, :completed, false)
      _task = create_task(crew, :pending, true)

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 true, with 0 tasks" do
      assignment = create_assignment(31, 1)

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 false, with 1 pending task left" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :pending, false)

      assert not Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 false, with completed tasks" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      _task = create_task(crew, :completed, false)

      assert not Assignment.Public.has_open_spots?(assignment)
    end

    test "mark_expired?/1 force=false, marked 1 expired task" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task1 = create_task(crew, :pending, false, 31)
      task2 = create_task(crew, :pending, false, 20)
      task3 = create_task(crew, :completed, false, 60)

      Assignment.Public.mark_expired_debug(assignment, false)

      assert %{expired: true} = Crew.Public.get_member!(task1.member_id)
      assert %{expired: false} = Crew.Public.get_member!(task2.member_id)
      assert %{expired: false} = Crew.Public.get_member!(task3.member_id)

      assert %{expired: true} = Crew.Public.get_task!(task1.id)
      assert %{expired: false} = Crew.Public.get_task!(task2.id)
      assert %{expired: false} = Crew.Public.get_task!(task3.id)
    end

    test "apply_expired?/1 force=true, marked all pending tasks" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task1 = create_task(crew, :pending, false, 31)
      task2 = create_task(crew, :pending, false, 20)
      task3 = create_task(crew, :completed, false, 60)

      Assignment.Public.mark_expired_debug(assignment, true)

      assert %{expired: true} = Crew.Public.get_member!(task1.member_id)
      assert %{expired: true} = Crew.Public.get_member!(task2.member_id)
      assert %{expired: false} = Crew.Public.get_member!(task3.member_id)

      assert %{expired: true} = Crew.Public.get_task!(task1.id)
      assert %{expired: true} = Crew.Public.get_task!(task2.id)
      assert %{expired: false} = Crew.Public.get_task!(task3.id)
    end

    test "apply_member/2 creates reward with deposit" do
      %{id: assignment_id, crew: crew, budget: %{id: budget_id}} =
        assignment = create_assignment(31, 1)

      task = create_task(crew, :pending, false, 31)

      Assignment.Public.mark_expired_debug(assignment, false)

      assert %{expired: true} = Crew.Public.get_member!(task.member_id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      member = Crew.Public.get_member!(task.member_id)
      %{id: user_id} = user = Accounts.get_user!(member.user_id)

      Assignment.Public.apply_member(assignment, user, 1000)

      idempotence_key = "assignment=#{assignment_id},user=#{user_id}"

      deposit_idempotence_key =
        "assignment=#{assignment_id},user=#{user_id},type=deposit,attempt=0"

      assert [
               %{
                 idempotence_key: ^idempotence_key,
                 amount: 1000,
                 attempt: 0,
                 user: %{id: ^user_id},
                 budget: %{id: ^budget_id},
                 deposit: %{idempotence_key: ^deposit_idempotence_key},
                 payment_id: nil
               }
             ] = Budget.Public.list_rewards(user, [:budget, :user, :deposit, :payment])
    end

    test "apply_member/2 re-uses expired member" do
      %{crew: crew} = assignment = create_assignment(31, 1)
      task = create_task(crew, :pending, false, 31)

      Assignment.Public.mark_expired_debug(assignment, false)

      assert %{expired: true} = Crew.Public.get_member!(task.member_id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      member = Crew.Public.get_member!(task.member_id)
      user = Accounts.get_user!(member.user_id)

      Assignment.Public.apply_member(assignment, user, 1000)

      assert %{expired: false} = Crew.Public.get_member!(task.member_id)
      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "rollback_expired_deposits/0 resets reward" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()

      assert [
               %{
                 amount: 1000,
                 attempt: 1,
                 deposit: nil,
                 payment: nil
               }
             ] = Budget.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               fund: %{balance_credit: 1000, balance_debit: 1000},
               reserve: %{balance_credit: 1000, balance_debit: 1000}
             } = Budget.Public.get!(assignment.budget_id)
    end

    test "apply_member/3 re-apply member creates reward with next attempt deposit" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, 2000)

      deposit_idempotence_key =
        "assignment=#{assignment.id},user=#{user.id},type=deposit,attempt=1"

      assert [
               %{
                 amount: 2000,
                 attempt: 1,
                 deposit: %{idempotence_key: ^deposit_idempotence_key},
                 payment: nil
               }
             ] = Budget.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               fund: %{balance_credit: 1000, balance_debit: 3000},
               reserve: %{balance_credit: 3000, balance_debit: 1000}
             } = Budget.Public.get!(assignment.budget_id)
    end

    test "payout_participant/2 creates transaction from budget reserve to user wallet" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, 2000)
      Assignment.Public.payout_participant(assignment, user)

      deposit_idempotence_key =
        "assignment=#{assignment.id},user=#{user.id},type=deposit,attempt=1"

      payment_idempotence_key = "assignment=#{assignment.id},user=#{user.id},type=payment"

      assert [
               %{
                 amount: 2000,
                 attempt: 1,
                 deposit: %{idempotence_key: ^deposit_idempotence_key},
                 payment: %{idempotence_key: ^payment_idempotence_key}
               }
             ] = Budget.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               fund: %{balance_credit: 1000, balance_debit: 3000},
               reserve: %{balance_credit: 3000, balance_debit: 3000}
             } = Budget.Public.get!(assignment.budget_id)
    end

    test "payout_participant/2 twice fails" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, 2000)
      assert {:ok, _} = Assignment.Public.payout_participant(assignment, user)

      assert {:error, _, :payment_already_available, %{}} =
               Assignment.Public.payout_participant(assignment, user)
    end

    test "rewarded_amount/2 after payout" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, 2000)
      Assignment.Public.payout_participant(assignment, user)

      assert Assignment.Public.rewarded_amount(assignment, user) == 2000
    end

    test "rewarded_amount/2 before payout" do
      user = Factories.insert!(:member)
      assignment = create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, 2000)

      assert Assignment.Public.rewarded_amount(assignment, user) == 0
    end

    test "open_spot_count/3 with 1 expired spot" do
      %{crew: crew} = assignment = create_assignment(10, 3)
      _task1 = create_task(crew, :pending, false, 10)
      _task2 = create_task(crew, :pending, true, 31)
      _task3 = create_task(crew, :completed, false)

      assert Assignment.Public.open_spot_count(assignment) == 1
    end

    test "open_spot_count/3 with 1 expired and one open spot" do
      %{crew: crew} = assignment = create_assignment(10, 4)
      _task1 = create_task(crew, :pending, false, 10)
      _task2 = create_task(crew, :pending, true, 31)
      _task3 = create_task(crew, :completed, false)

      assert Assignment.Public.open_spot_count(assignment) == 2
    end

    test "open_spot_count/3 with all open spots" do
      assignment = create_assignment(31, 3)
      assert Assignment.Public.open_spot_count(assignment) == 3
    end

    test "next_action (Assignment.CheckRejection) after rejection of task" do
      %{crew: crew} = create_assignment(31, 3)
      %{id: task_id, member: %{user: user}} = create_task(crew, :pending, false, 10)

      Crew.Public.reject_task(task_id, %{category: :other, message: "rejected"})

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

      Crew.Public.reject_task(task_id, %{category: :other, message: "rejected"})
      Crew.Public.accept_task(task_id)

      url_resolver = fn target, _ ->
        case target do
          Systems.Assignment.LandingPage -> "/assignment"
        end
      end

      refute_next_action(user, url_resolver, "/assignment")
    end

    test "exclude/2" do
      %{id: id1} = assignment1 = create_assignment(31, 2)
      %{id: id2} = assignment2 = create_assignment(31, 2)

      Assignment.Public.exclude(assignment1, assignment2)

      assert %{
               excluded: [%Systems.Assignment.Model{id: ^id2}]
             } = Assignment.Public.get!(assignment1.id, [:excluded])

      assert %{
               excluded: [%Systems.Assignment.Model{id: ^id1}]
             } = Assignment.Public.get!(assignment2.id, [:excluded])
    end

    test "include/2" do
      assignment1 = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)

      {:ok, _} = Assignment.Public.exclude(assignment1, assignment2)

      assignment1 = Assignment.Public.get!(assignment1.id, [:excluded])
      assignment2 = Assignment.Public.get!(assignment2.id, [:excluded])

      {:ok, _} = Assignment.Public.include(assignment1, assignment2)

      assert %{
               excluded: []
             } = Assignment.Public.get!(assignment1.id, [:excluded])

      assert %{
               excluded: []
             } = Assignment.Public.get!(assignment2.id, [:excluded])
    end

    test "excluded?/2 false: user has no task on excluded assignment" do
      assignment1 = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)

      user = Factories.insert!(:member)

      Assignment.Public.exclude(assignment1, assignment2)
      assert Assignment.Public.excluded?(assignment2, user) == false
    end

    test "excluded?/2 false: user has task on non-excluded assignment" do
      %{crew: crew1} = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)

      %{member: %{user: user}} = create_task(crew1, :pending, false, 10)
      assert Assignment.Public.excluded?(assignment2, user) == false
    end

    test "excluded?/2 true: user has task on excluded assignment" do
      %{crew: crew1} = assignment1 = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)

      %{member: %{user: user}} = create_task(crew1, :pending, false, 10)

      Assignment.Public.exclude(assignment1, assignment2)
      assert Assignment.Public.excluded?(assignment2, user) == true
    end

    test "excluded?/2 user has task on multiple excluded assignment" do
      %{crew: crew1} = assignment1 = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)
      assignment3 = create_assignment(31, 2)
      assignment4 = create_assignment(31, 2)

      %{member: %{user: user}} = create_task(crew1, :pending, false, 10)

      Assignment.Public.exclude(assignment1, assignment2)
      Assignment.Public.exclude(assignment1, assignment3)

      assert Assignment.Public.excluded?(assignment2, user) == true
      assert Assignment.Public.excluded?(assignment3, user) == true
      assert Assignment.Public.excluded?(assignment4, user) == false
    end

    test "excluded?/2 user has no task on multiple excluded assignment" do
      %{crew: crew1} = assignment1 = create_assignment(31, 2)
      assignment2 = create_assignment(31, 2)
      assignment3 = create_assignment(31, 2)
      assignment4 = create_assignment(31, 2)

      %{member: %{user: user}} = create_task(crew1, :pending, false, 10)

      Assignment.Public.exclude(assignment4, assignment2)
      Assignment.Public.exclude(assignment4, assignment3)

      assert Assignment.Public.excluded?(assignment1, user) == false
      assert Assignment.Public.excluded?(assignment2, user) == false
      assert Assignment.Public.excluded?(assignment3, user) == false
      assert Assignment.Public.excluded?(assignment4, user) == false
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
