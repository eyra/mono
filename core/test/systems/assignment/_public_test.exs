defmodule Systems.Assignment.PublicTest do
  use Core.DataCase
  import Ecto.Query
  import Systems.NextAction.TestHelper

  alias Systems.Assignment
  alias Systems.Bookkeeping
  alias Systems.Crew
  alias Systems.Fund
  alias Systems.Monitor
  alias Systems.Budget

  alias Core.Factories

  describe "assignment instances" do
    test "obtain_instance!/3 inserts an instance and inserts external panel info" do
      assignment = Factories.insert!(:assignment)
      %{user: user} = Factories.build(:affiliate_user) |> Repo.insert!()

      Assignment.Public.obtain_instance!(assignment, user)

      assert Assignment.Public.get_instance(assignment, user) != nil
    end

    test "obtain_instance!/3 updates instance" do
      assignment = Factories.insert!(:assignment)
      %{user: user} = Factories.build(:affiliate_user) |> Repo.insert!()

      instance = Assignment.Public.obtain_instance!(assignment, user)
      instance_2 = Assignment.Public.obtain_instance!(assignment, user)

      assert instance.id == instance_2.id
    end

    test "get_instance/2 returns nil if no instance exists" do
      assignment = Factories.insert!(:assignment)
      %{user: user} = Factories.build(:affiliate_user) |> Repo.insert!()

      assert Assignment.Public.get_instance(assignment, user) == nil
    end

    test "get_instance/2 returns instance if it exists" do
      assignment = Factories.insert!(:assignment)
      %{user: user} = Factories.build(:affiliate_user) |> Repo.insert!()

      %{id: instance_id} = Assignment.Public.obtain_instance!(assignment, user)

      assert %{id: ^instance_id} = Assignment.Public.get_instance(assignment, user)
    end

    test "list_instances/1 returns all instances" do
      assignment = Factories.insert!(:assignment)
      %{user: user} = Factories.build(:affiliate_user) |> Repo.insert!()
      %{user: user_2} = Factories.build(:affiliate_user) |> Repo.insert!()
      %{user: user_3} = Factories.build(:affiliate_user) |> Repo.insert!()

      %{id: instance_id} = Assignment.Public.obtain_instance!(assignment, user)
      %{id: instance_id_2} = Assignment.Public.obtain_instance!(assignment, user_2)
      %{id: instance_id_3} = Assignment.Public.obtain_instance!(assignment, user_3)

      assert [
               %{id: ^instance_id},
               %{id: ^instance_id_2},
               %{id: ^instance_id_3}
             ] = Assignment.Public.list_instances(assignment)
    end
  end

  describe "assignments" do
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

    test "list_participants?/1 with 1 affiliate user" do
      affiliate = Factories.build(:affiliate) |> Repo.insert!()

      affiliate_user =
        %{identifier: identifier, user: %{id: user_id}} =
        Factories.insert!(:affiliate_user, %{identifier: "test", affiliate: affiliate})

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: affiliate_user.user})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      assignment =
        Factories.insert!(:assignment, %{
          affiliate: affiliate,
          crew: crew,
          special: :data_donation,
          status: :online
        })

      %{id: member_id} = Crew.Factories.create_member(crew, affiliate_user.user)

      assert [
               %{user_id: ^user_id, member_id: ^member_id, public_id: 1, external_id: ^identifier}
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
      %{id: assignment_id, crew: crew, fund: %{id: fund_id}} =
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
                 fund: %{id: ^fund_id},
                 deposit: %{idempotence_key: ^deposit_idempotence_key},
                 payment_id: nil
               }
             ] = Fund.Public.list_rewards(user, [:fund, :user, :deposit, :payment])
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
             ] = Fund.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               available: %{balance_credit: 1000, balance_debit: 1000},
               pending: %{balance_credit: 1000, balance_debit: 1000}
             } = Fund.Public.get!(assignment.fund_id)
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
             ] = Fund.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               available: %{balance_credit: 1000, balance_debit: 3000},
               pending: %{balance_credit: 3000, balance_debit: 1000}
             } = Fund.Public.get!(assignment.fund_id)
    end

    test "payout_participant/2 creates transaction from fund reserve to user wallet" do
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
             ] = Fund.Public.list_rewards(user, [:deposit, :payment])

      assert %{
               available: %{balance_credit: 1000, balance_debit: 3000},
               pending: %{balance_credit: 3000, balance_debit: 3000}
             } = Fund.Public.get!(assignment.fund_id)
    end

    test "payout_participant/2 is idempotent" do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.apply_member(assignment, user, ["task1"], 1000)
      Assignment.Public.mark_expired_debug(assignment, true)
      Assignment.Public.rollback_expired_deposits()
      Assignment.Public.apply_member(assignment, user, ["task1"], 2000)
      assert {:ok, _} = Assignment.Public.payout_participant(assignment, user)

      assert {:ok, %Systems.Fund.RewardModel{status: :approved}} =
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

  describe "approval flow (researcher UI wiring)" do
    setup do
      user = Factories.insert!(:member)
      %{fund: fund, crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
      member = Crew.Factories.create_member(crew, user)

      task =
        Crew.Factories.create_task(
          crew,
          member,
          ["task1", "member=#{member.id}"],
          status: :completed
        )

      idempotence_key = Assignment.Public.idempotence_key(assignment, user)
      {:ok, _} = Systems.Fund.Public.create_reward(fund, 1000, user, idempotence_key)
      {:ok, _} = Systems.Fund.Public.mark_pending_approval(idempotence_key)

      {:ok,
       user: user,
       assignment: assignment,
       member: member,
       task: task,
       idempotence_key: idempotence_key}
    end

    test "Crew.Public.accept_task triggers reward approval via switch", %{
      task: task,
      idempotence_key: idempotence_key
    } do
      {:ok, _} = Crew.Public.accept_task(task.id)

      assert %{status: :approved, payment_id: payment_id} =
               Systems.Fund.Public.get_reward(idempotence_key, [])

      refute is_nil(payment_id)
    end

    test "Assignment.Public.reject_task flips reward to :rejected and rolls back deposit", %{
      assignment: assignment,
      task: task,
      idempotence_key: idempotence_key
    } do
      [first_category | _] = Crew.RejectCategories.values()
      rejection = %{category: first_category, message: "test"}

      assert {:ok, _} = Assignment.Public.reject_task(assignment, task, rejection)

      assert %{status: :rejected, deposit_id: nil} =
               Systems.Fund.Public.get_reward(idempotence_key, [])
    end
  end

  describe "list_pending_payouts/1" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      %{fund: fund, crew: crew} = assignment
      member = Crew.Factories.create_member(crew, user)

      idempotence_key = Assignment.Public.idempotence_key(assignment, user)
      {:ok, _} = Systems.Fund.Public.create_reward(fund, 1000, user, idempotence_key)
      {:ok, _} = Systems.Fund.Public.mark_pending_approval(idempotence_key)

      assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

      {:ok, assignment: assignment, crew: crew, member: member}
    end

    test "lists a pending-approval reward backed by a completed task", %{
      assignment: assignment,
      crew: crew,
      member: member
    } do
      Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"],
        status: :completed
      )

      assert [%{amount: 1000}] = Assignment.Public.list_pending_payouts(assignment)
    end

    test "lists the reward even when the participant's newest task is not the completed one", %{
      assignment: assignment,
      crew: crew,
      member: member
    } do
      Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"],
        status: :completed,
        minutes_ago: 60
      )

      # A newer (higher-id) non-completed task must not hide the payout.
      Crew.Factories.create_task(crew, member, ["task2", "member=#{member.id}"], minutes_ago: 1)

      assert [%{amount: 1000}] = Assignment.Public.list_pending_payouts(assignment)
    end
  end

  describe "add_participant!/2 reserves reward at join" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)

      assignment.info
      |> Ecto.Changeset.change(%{subject_reward: 100})
      |> Core.Repo.update!()

      assignment =
        Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

      {:ok, user: user, assignment: assignment}
    end

    test "creates a :reserved reward with deposit", %{user: user, assignment: assignment} do
      Assignment.Public.add_participant!(assignment, user)

      idempotence_key = Assignment.Public.idempotence_key(assignment, user)

      assert %{status: :reserved, amount: 100, deposit_id: deposit_id} =
               Fund.Public.get_reward(idempotence_key, [])

      refute is_nil(deposit_id)
    end

    test "Towel rollback returns money to fund.available and clears deposit", %{
      user: user,
      assignment: %{fund_id: fund_id, crew: crew} = assignment
    } do
      Assignment.Public.add_participant!(assignment, user)
      idempotence_key = Assignment.Public.idempotence_key(assignment, user)
      original_available_after_join = Fund.Model.amount_available(Fund.Public.get!(fund_id))

      member = Crew.Public.get_member(crew, user)

      member
      |> Ecto.Changeset.change(%{
        expired: true,
        expire_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })
      |> Core.Repo.update!()

      Assignment.Public.rollback_expired_deposits()

      assert %{deposit_id: nil} = Fund.Public.get_reward(idempotence_key, [])

      assert Fund.Model.amount_available(Fund.Public.get!(fund_id)) ==
               original_available_after_join + 100
    end

    test "is a no-op when subject_reward is 0", %{user: user, assignment: assignment} do
      assignment.info
      |> Ecto.Changeset.change(%{subject_reward: 0})
      |> Core.Repo.update!()

      assignment =
        Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

      Assignment.Public.add_participant!(assignment, user)

      idempotence_key = Assignment.Public.idempotence_key(assignment, user)
      assert nil == Fund.Public.get_reward(idempotence_key, [])
    end

    test "resolves currency for pre-fix fund (currency nil, ledger :EUR) without crashing", %{
      user: user,
      assignment: %{fund_id: fund_id} = assignment
    } do
      eur_ledger = Core.Repo.insert!(Budget.CurrencyLedgerModel.create(:EUR))
      fund = Fund.Public.get!(fund_id)

      fund
      |> Ecto.Changeset.change(%{currency_id: nil, currency_ledger_id: eur_ledger.id})
      |> Core.Repo.update!()

      # The resolved euro currency is :legal, which activates the fund balance
      # guard; give the fund enough available funds so the deposit succeeds.
      fund.available
      |> Ecto.Changeset.change(%{balance_credit: 10_000})
      |> Core.Repo.update!()

      assignment =
        Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

      Assignment.Public.add_participant!(assignment, user)

      idempotence_key = Assignment.Public.idempotence_key(assignment, user)

      assert %{status: :reserved, amount: 100, deposit_id: deposit_id} =
               Fund.Public.get_reward(idempotence_key, [])

      refute is_nil(deposit_id)
    end
  end

  describe "list_completed_payouts/1" do
    setup do
      user = Factories.insert!(:member)
      %{fund: fund, crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
      # Reload to pick up public_id assigned by the crew_members trigger.
      member = Crew.Factories.create_member(crew, user) |> Repo.reload!()

      {:ok, user: user, fund: fund, crew: crew, member: member, assignment: assignment}
    end

    defp insert_paid_reward(user, fund, opts \\ []) do
      amount = Keyword.get(opts, :amount, 500)
      paid_at = Keyword.get(opts, :paid_at)
      with_payment? = Keyword.get(opts, :with_payment, true)

      payment =
        if with_payment? do
          entry =
            Factories.insert!(:book_entry, %{
              idempotence_key: "pay-#{System.unique_integer([:positive])}",
              journal_message: "test_list_completed_payouts"
            })

          if paid_at do
            from(e in Bookkeeping.EntryModel, where: e.id == ^entry.id)
            |> Repo.update_all(set: [inserted_at: paid_at])
          end

          Repo.get!(Bookkeeping.EntryModel, entry.id)
        end

      Factories.insert!(:reward, %{
        idempotence_key: "rw-#{System.unique_integer([:positive])}",
        amount: amount,
        status: :paid,
        user: user,
        fund: fund,
        payment: payment
      })
    end

    test "returns paid rewards as rows joined to crew members",
         %{user: user, fund: fund, member: member, assignment: assignment} do
      reward = insert_paid_reward(user, fund, amount: 750)

      assert [
               %{
                 reward_id: reward_id,
                 member_public_id: member_public_id,
                 amount: 750,
                 currency: %Fund.CurrencyModel{},
                 paid_at: %NaiveDateTime{}
               }
             ] = Assignment.Public.list_completed_payouts(assignment)

      assert reward_id == reward.id
      assert member_public_id == member.public_id
    end

    test "excludes rewards that are not yet paid",
         %{user: user, fund: fund, assignment: assignment} do
      insert_paid_reward(user, fund)

      Factories.insert!(:reward, %{
        idempotence_key: "rw-approved-#{System.unique_integer([:positive])}",
        amount: 100,
        status: :approved,
        user: user,
        fund: fund
      })

      assert [%{amount: 500}] = Assignment.Public.list_completed_payouts(assignment)
    end

    test "returns [] when the assignment has no fund" do
      assignment = Factories.insert!(:assignment, %{fund: nil})

      assert [] = Assignment.Public.list_completed_payouts(assignment)
    end

    test "sorts rows by paid_at descending (most recent first)",
         %{user: user, fund: fund, assignment: assignment} do
      %{id: older_id} = insert_paid_reward(user, fund, paid_at: ~N[2024-01-01 00:00:00])
      %{id: newer_id} = insert_paid_reward(user, fund, paid_at: ~N[2025-06-01 00:00:00])

      assert [%{reward_id: ^newer_id}, %{reward_id: ^older_id}] =
               Assignment.Public.list_completed_payouts(assignment)
    end

    test "falls back to reward.updated_at when the reward has no payment",
         %{user: user, fund: fund, assignment: assignment} do
      %{updated_at: updated_at} = insert_paid_reward(user, fund, with_payment: false)

      assert [%{paid_at: ^updated_at}] = Assignment.Public.list_completed_payouts(assignment)
    end
  end

  describe "has_budget_capacity?/1" do
    setup do
      legal = Fund.Factories.create_currency("eur_capacity", :legal, "€", 2)
      virtual = Fund.Factories.create_currency("credits_capacity", :virtual, "c", 0)
      {:ok, legal: legal, virtual: virtual}
    end

    test "crashes on non-Assignment input" do
      assert_raise FunctionClauseError, fn ->
        apply(Assignment.Public, :has_budget_capacity?, [%{}])
      end
    end

    test "true when the legal fund covers the reward", %{legal: legal} do
      fund = Fund.Factories.create_fund("capacity_ok", legal)
      assignment = funded_assignment(fund, 100)

      assert Assignment.Public.has_budget_capacity?(assignment)
    end

    test "true at the exact boundary where available equals reward", %{legal: legal} do
      fund = Fund.Factories.create_fund("capacity_boundary", legal)
      assignment = funded_assignment(fund, 5000)

      assert Assignment.Public.has_budget_capacity?(assignment)
    end

    test "false when the legal fund cannot cover one more reward", %{legal: legal} do
      fund = Fund.Factories.create_fund("capacity_broke", legal)
      assignment = funded_assignment(fund, 6000)

      refute Assignment.Public.has_budget_capacity?(assignment)
    end

    test "true for a free assignment regardless of balance", %{legal: legal} do
      fund = Fund.Factories.create_fund("capacity_free", legal)
      assignment = funded_assignment(fund, 0)

      assert Assignment.Public.has_budget_capacity?(assignment)
    end

    test "true for a virtual currency even below the reward", %{virtual: virtual} do
      fund = Fund.Factories.create_fund("capacity_virtual", virtual)
      assignment = funded_assignment(fund, 6000)

      assert Assignment.Public.has_budget_capacity?(assignment)
    end

    # A paid assignment whose fund can't be resolved fails closed (treated as
    # full) and logs a warning via the budget_capacity/1 fallback. The warning
    # itself isn't asserted here because the test logger runs at :error.
    test "false for a paid assignment without a fund" do
      refute Assignment.Public.has_budget_capacity?(funded_assignment(nil, 6000))
    end
  end

  defp funded_assignment(fund, subject_reward) do
    info =
      Factories.insert!(:assignment_info, %{
        subject_count: 1,
        subject_reward: subject_reward,
        duration: "31",
        language: :en,
        devices: [:desktop]
      })

    Factories.insert!(:assignment, %{info: info, fund: fund})
  end
end
