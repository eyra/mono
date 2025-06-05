defmodule Systems.Assignment.PublicTest do
  use Core.DataCase
  import Systems.NextAction.TestHelper

  describe "assignments" do
    alias Systems.Assignment
    alias Systems.Crew
    alias Systems.Budget
    alias Systems.Monitor

    alias Core.Factories

    test "list_participants?/1 with 1 expired member" do
      user = %{id: user_id} = Factories.insert!(:member)

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: user})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      assignment =
        Factories.insert!(:assignment, %{
          crew: crew,
          special: :data_donation,
          status: :online
        })

      %{id: member_id} = Crew.Factories.create_member(crew, user, %{expired: true})

      assert [
               %{user_id: ^user_id, member_id: ^member_id, public_id: 1, external_id: nil}
             ] = Assignment.Public.list_participants(assignment)
    end

    test "list_participants?/1 with 1 active member" do
      user = %{id: user_id} = Factories.insert!(:member)

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: user})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      assignment =
        Factories.insert!(:assignment, %{
          crew: crew,
          special: :data_donation,
          status: :online
        })

      %{id: member_id} = Crew.Factories.create_member(crew, user)

      assert [
               %{user_id: ^user_id, member_id: ^member_id, public_id: 1, external_id: nil}
             ] = Assignment.Public.list_participants(assignment)
    end

    test "list_participants?/1 with 1 expired member and 1 active member" do
      user1 = %{id: user_1_id} = Factories.insert!(:member)
      user2 = %{id: user_2_id} = Factories.insert!(:member)

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: user1}),
            Factories.build(:participant, %{user: user2})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      assignment =
        Factories.insert!(:assignment, %{
          crew: crew,
          special: :data_donation,
          status: :online
        })

      %{id: member_1_id} = Crew.Factories.create_member(crew, user1)
      %{id: member_2_id} = Crew.Factories.create_member(crew, user2)

      assert [
               %{user_id: ^user_1_id, member_id: ^member_1_id, public_id: 1, external_id: nil},
               %{user_id: ^user_2_id, member_id: ^member_2_id, public_id: 2, external_id: nil}
             ] = Assignment.Public.list_participants(assignment)
    end

    test "list_participants?/1 with 1 external user" do
      external_user =
        %{external_id: external_id, user: %{id: user_id}} = Factories.insert!(:external_user)

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: external_user.user})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      assignment =
        Factories.insert!(:assignment, %{
          crew: crew,
          special: :data_donation,
          status: :online
        })

      %{id: member_id} = Crew.Factories.create_member(crew, external_user.user)

      assert [
               %{
                 user_id: ^user_id,
                 member_id: ^member_id,
                 public_id: 1,
                 external_id: ^external_id
               }
             ] = Assignment.Public.list_participants(assignment)
    end

    test "has_open_spots?/1 true, with 1 expired member" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)

      user = Factories.insert!(:member)
      Crew.Factories.create_member(crew, user, %{expired: true})

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 true, with 1 expired member and 1 normal member" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 2)
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      Crew.Factories.create_member(crew, user1, %{expired: true})
      Crew.Factories.create_member(crew, user2)

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "has_open_spots?/1 true, with 0 members" do
      assignment = Assignment.Factories.create_assignment(31, 1)

      assert Assignment.Public.has_open_spots?(assignment)
    end

    test "mark_expired_debug?/1 force=false, marked 1 expired task" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      user3 = Factories.insert!(:member)

      member1 = Crew.Factories.create_member(crew, user1)
      member2 = Crew.Factories.create_member(crew, user2)
      member3 = Crew.Factories.create_member(crew, user3)

      task1 = Crew.Factories.create_task(crew, member1, ["task1"])
      task2 = Crew.Factories.create_task(crew, member2, ["task2"], minutes_ago: 20)

      task3 =
        Crew.Factories.create_task(crew, member3, ["task3"], status: :completed, minutes_ago: 60)

      Assignment.Public.mark_expired_debug(assignment, false)

      assert is_nil(Crew.Public.get_member(crew, user1))
      assert %{expired: false} = Crew.Public.get_member(crew, user2)
      assert %{expired: false} = Crew.Public.get_member(crew, user3)

      assert %{expired: true} = Crew.Public.get_task!(task1.id)
      assert %{expired: false} = Crew.Public.get_task!(task2.id)
      assert %{expired: false} = Crew.Public.get_task!(task3.id)
    end

    test "mark_expired_debug?/1 force=true, marked all pending tasks" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)

      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      user3 = Factories.insert!(:member)

      member1 = Crew.Factories.create_member(crew, user1)
      member2 = Crew.Factories.create_member(crew, user2)
      member3 = Crew.Factories.create_member(crew, user3)

      task1 = Crew.Factories.create_task(crew, member1, ["task1"])
      task2 = Crew.Factories.create_task(crew, member2, ["task2"], minutes_ago: 20)

      task3 =
        Crew.Factories.create_task(crew, member3, ["task3"], status: :completed, minutes_ago: 60)

      Assignment.Public.mark_expired_debug(assignment, true)

      assert is_nil(Crew.Public.get_member(crew, user1))
      assert is_nil(Crew.Public.get_member(crew, user2))
      assert %{expired: false} = Crew.Public.get_member(crew, user3)

      assert %{expired: true} = Crew.Public.get_task!(task1.id)
      assert %{expired: true} = Crew.Public.get_task!(task2.id)
      assert %{expired: false} = Crew.Public.get_task!(task3.id)
    end

    test "apply_member/4 creates reward with deposit" do
      %{id: assignment_id, crew: crew, budget: %{id: budget_id}} =
        assignment = Assignment.Factories.create_assignment(31, 1)

      %{id: user_id} = user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew, user)

      task = Crew.Factories.create_task(crew, member, ["task1"])

      Assignment.Public.mark_expired_debug(assignment, false)

      assert is_nil(Crew.Public.get_member(crew, user))
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)

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

    test "apply_member/4 re-uses expired member" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew, user)
      task = Crew.Factories.create_task(crew, member, ["task1"])

      Assignment.Public.mark_expired_debug(assignment, false)

      assert is_nil(Crew.Public.get_member(crew, user))
      assert %{expired: true} = Crew.Public.get_task!(task.id)

      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)

      assert %{expired: false} = Crew.Public.get_member(crew, user)
      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "decline_member/2 does expire member and tasks and updates metric" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew, user)
      task = Crew.Factories.create_task(crew, member, ["task1"])
      metric = ["assignment=#{assignment.id}", "topic=declined", "user=#{user.id}"]

      assert %{expired: false} = Crew.Public.get_member(crew, user)
      assert %{expired: false} = Crew.Public.get_task!(task.id)
      assert 0 = Monitor.Public.count(metric)

      Assignment.Public.decline_member(assignment, user)

      assert %{expired: true} = Crew.Public.get_member!(member.id)
      assert %{expired: true} = Crew.Public.get_task!(task.id)
      assert 1 = Monitor.Public.count(metric)
    end

    test "rollback_expired_deposits/0 resets reward" do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
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
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)

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
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)
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
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)
      assert {:ok, _} = Assignment.Public.payout_participant(assignment, user)

      assert {:error, _, :payment_already_available, %{}} =
               Assignment.Public.payout_participant(assignment, user)
    end

    test "rewarded_amount/2 after payout" do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)
      Assignment.Public.payout_participant(assignment, user)

      assert Assignment.Public.rewarded_amount(assignment, user) == 2000
    end

    test "rewarded_amount/2 before payout" do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)

      assert Assignment.Public.rewarded_amount(assignment, user) == 0
    end

    test "open_spot_count/3 with 1 expired member" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(10, 1)

      user = Factories.insert!(:member)
      Crew.Factories.create_member(crew, user, %{expired: true})

      assert Assignment.Public.open_spot_count(assignment) == 1
    end

    test "open_spot_count/3 with 1 expired and one open spot" do
      %{crew: crew} = assignment = Assignment.Factories.create_assignment(10, 2)
      user = Factories.insert!(:member)
      Crew.Factories.create_member(crew, user, %{expired: true})

      assert Assignment.Public.open_spot_count(assignment) == 2
    end

    test "open_spot_count/3 with all open spots" do
      assignment = Assignment.Factories.create_assignment(31, 3)
      assert Assignment.Public.open_spot_count(assignment) == 3
    end

    test "next_action (Assignment.CheckRejection) after rejection of task" do
      %{id: id, crew: crew} = Assignment.Factories.create_assignment(31, 3)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew, user)

      %{id: task_id} =
        Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"],
          minutes_ago: 10
        )

      Crew.Public.reject_task(task_id, %{category: :other, message: "rejected"})

      assert_next_action(user, "/assignment/#{id}/landing")
    end

    test "next_action cleared after acceptence of task" do
      %{id: id, crew: crew} = Assignment.Factories.create_assignment(31, 3)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew, user)

      %{id: task_id} =
        Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"],
          minutes_ago: 10
        )

      Crew.Public.reject_task(task_id, %{category: :other, message: "rejected"})
      Crew.Public.accept_task(task_id)

      refute_next_action(user, "/assignment/#{id}/landing")
    end

    test "exclude/2" do
      %{id: id1} = assignment1 = Assignment.Factories.create_assignment(31, 2)
      %{id: id2} = assignment2 = Assignment.Factories.create_assignment(31, 2)

      Assignment.Public.exclude(assignment1, assignment2)

      assert %{
               excluded: [%Systems.Assignment.Model{id: ^id2}]
             } = Assignment.Public.get!(assignment1.id, [:excluded])

      assert %{
               excluded: [%Systems.Assignment.Model{id: ^id1}]
             } = Assignment.Public.get!(assignment2.id, [:excluded])
    end

    test "include/2" do
      assignment1 = Assignment.Factories.create_assignment(31, 2)
      assignment2 = Assignment.Factories.create_assignment(31, 2)

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
      assignment1 = Assignment.Factories.create_assignment(31, 2)
      assignment2 = Assignment.Factories.create_assignment(31, 2)

      user = Factories.insert!(:member)

      Assignment.Public.exclude(assignment1, assignment2)
      assert Assignment.Public.excluded?(assignment2, user) == false
    end

    test "excluded?/2 false: user has task on non-excluded assignment" do
      %{crew: crew1} = Assignment.Factories.create_assignment(31, 2)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew1, user)

      assignment2 = Assignment.Factories.create_assignment(31, 2)

      Crew.Factories.create_task(crew1, member, ["task1"], minutes_ago: 10)
      assert Assignment.Public.excluded?(assignment2, user) == false
    end

    test "excluded?/2 true: user has task on excluded assignment" do
      %{crew: crew1} = assignment1 = Assignment.Factories.create_assignment(31, 2)
      assignment2 = Assignment.Factories.create_assignment(31, 2)

      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew1, user)

      Crew.Factories.create_task(crew1, member, ["task1"], minutes_ago: 10)

      Assignment.Public.exclude(assignment1, assignment2)
      assert Assignment.Public.excluded?(assignment2, user) == true
    end

    test "excluded?/2 user has task on multiple excluded assignment" do
      %{crew: crew1} = assignment1 = Assignment.Factories.create_assignment(31, 2)
      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew1, user)

      assignment2 = Assignment.Factories.create_assignment(31, 2)
      assignment3 = Assignment.Factories.create_assignment(31, 2)
      assignment4 = Assignment.Factories.create_assignment(31, 2)

      Crew.Factories.create_task(crew1, member, ["task1"], minutes_ago: 10)

      Assignment.Public.exclude(assignment1, assignment2)
      Assignment.Public.exclude(assignment1, assignment3)

      assert Assignment.Public.excluded?(assignment2, user) == true
      assert Assignment.Public.excluded?(assignment3, user) == true
      assert Assignment.Public.excluded?(assignment4, user) == false
    end

    test "excluded?/2 user has no task on multiple excluded assignment" do
      %{crew: crew1} = assignment1 = Assignment.Factories.create_assignment(31, 2)
      assignment2 = Assignment.Factories.create_assignment(31, 2)
      assignment3 = Assignment.Factories.create_assignment(31, 2)
      assignment4 = Assignment.Factories.create_assignment(31, 2)

      user = Factories.insert!(:member)
      member = Crew.Factories.create_member(crew1, user)

      Crew.Factories.create_task(crew1, member, ["task1"], minutes_ago: 10)

      Assignment.Public.exclude(assignment4, assignment2)
      Assignment.Public.exclude(assignment4, assignment3)

      assert Assignment.Public.excluded?(assignment1, user) == false
      assert Assignment.Public.excluded?(assignment2, user) == false
      assert Assignment.Public.excluded?(assignment3, user) == false
      assert Assignment.Public.excluded?(assignment4, user) == false
    end
  end
end
