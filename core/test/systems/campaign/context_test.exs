defmodule Systems.Campaign.ContextTest do
  use Core.DataCase

  describe "assignments" do
    alias Systems.{
      Campaign,
      Crew,
      Pool,
      Bookkeeping,
      Budget
    }

    alias Core.Factories
    alias CoreWeb.UI.Timestamp

    setup do
      currency = Budget.Factories.create_currency("fake_currency", "ƒ", 2)
      budget = Budget.Factories.create_budget("test", currency)
      user = Factories.insert!(:member)
      {:ok, currency: currency, budget: budget, user: user}
    end

    test "mark_expired_debug?/0 should mark 1 expired task in online campaign", %{budget: budget} do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted, budget)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 0 expired tasks in submitted campaign", %{
      budget: budget
    } do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:submitted, budget)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in closed campaign", %{budget: budget} do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, budget, nil, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in scheduled campaign", %{
      budget: budget
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, budget, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in submitted campaign", %{
      budget: budget
    } do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:submitted, budget)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in closed campaign", %{budget: budget} do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, budget, nil, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in scheduled campaign", %{
      budget: budget
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, budget, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "payout_participant/2 One transaction of one student", %{budget: budget} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted, budget)

      create_task(student, crew, :accepted, false, -31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Context.payout_participant(assignment, student)

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 Two transactions of one student", %{budget: budget} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted, budget)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted, budget)

      create_task(student, crew1, :accepted, false, -31)
      create_task(student, crew2, :accepted, false, -31)

      Budget.Factories.create_reward(assignment1, student, budget)
      Budget.Factories.create_reward(assignment2, student, budget)

      Campaign.Context.payout_participant(assignment1, student)
      Campaign.Context.payout_participant(assignment2, student)

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 2

      assert %{credit: 10_000, debit: 5004} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 Two transactions of two students", %{budget: budget} do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted, budget)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted, budget)

      create_task(student1, crew1, :accepted, false, -31)
      create_task(student1, crew2, :accepted, false, -31)
      create_task(student2, crew1, :accepted, false, -31)
      create_task(student2, crew2, :accepted, false, -31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      Campaign.Context.payout_participant(assignment1, student1)
      Campaign.Context.payout_participant(assignment2, student1)
      Campaign.Context.payout_participant(assignment1, student2)
      Campaign.Context.payout_participant(assignment2, student2)

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student2.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 4

      assert %{credit: 10_000, debit: 5008} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student2.id})
    end

    test "payout_participant/2 One transaction of one student (via signals)", %{budget: budget} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted, budget)
      task = create_task(student, crew, :pending, false, -31)
      Budget.Factories.create_reward(assignment, student, budget)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task)

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 One transaction of one student failed: task already accepted (via signals)",
         %{budget: budget} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted, budget)
      task = create_task(student, crew, :accepted, false, -31)
      Budget.Factories.create_reward(assignment, student, budget)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task)

      assert Enum.empty?(Bookkeeping.Context.list_accounts(["wallet"]))

      assert Enum.empty?(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id}))
    end

    test "payout_participant/2 Multiple transactions of two students (via signals)", %{
      budget: budget
    } do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted, budget)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted, budget)

      task1 = create_task(student1, crew1, :pending, false, -31)
      task2 = create_task(student1, crew2, :pending, false, -31)
      task3 = create_task(student2, crew1, :pending, false, -31)
      _task4 = create_task(student2, crew2, :pending, false, -31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task1)
      Crew.Context.accept_task(task2)
      Crew.Context.accept_task(task3)

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student2.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 3

      assert %{credit: 10_000, debit: 5006} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student2.id})
    end

    test "sync_student_credits/0 One transaction of one student", %{budget: budget} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted, budget)

      create_task(student, crew, :accepted, false, -31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student.id})
    end

    test "sync_student_credits/0 One transaction of one student (sync twice -> no error)", %{
      budget: budget
    } do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted, budget)

      create_task(student, crew, :accepted, false, -31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Context.sync_student_credits()
      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student.id})
    end

    test "sync_student_credits/0 Two transactions of two students", %{budget: budget} do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted, budget)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted, budget)

      create_task(student1, crew1, :accepted, false, -31)
      create_task(student1, crew2, :accepted, false, -31)
      create_task(student2, crew1, :accepted, false, -31)
      create_task(student2, crew2, :accepted, false, -31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "fake_currency", student2.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "test"})) == 4

      assert %{credit: 10_000, debit: 5008} = Bookkeeping.Context.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "fake_currency", student2.id})
    end

    test "update_pool_participations/3 add", %{user: %{id: user_id} = user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]
      Campaign.Context.update_pool_participations(user, [iba_1], [])

      assert %{
               participants: [%{id: ^user_id}]
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "update_pool_participations/3 add 2 for 1 pool", %{user: %{id: user_id} = user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]
      bk_1_h = ["vu", "sbe", "bk", ":year1", ":resit", ":2021"]

      Campaign.Context.update_pool_participations(user, [iba_1, bk_1_h], [])

      assert %{
               participants: [%{id: ^user_id}]
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "update_pool_participations/3 add 2 for 2 pools", %{user: %{id: user_id} = user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]
      bk_2_h = ["vu", "sbe", "bk", ":year2", ":resit", ":2021"]

      Campaign.Context.update_pool_participations(user, [iba_1, bk_2_h], [])

      assert %{
               participants: [%{id: ^user_id}]
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: [%{id: ^user_id}]
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "update_pool_participations/3 remove 1 for 1 pools", %{user: user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]

      Campaign.Context.update_pool_participations(user, [iba_1], [])
      Campaign.Context.update_pool_participations(user, [], [iba_1])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "update_pool_participations/3 remove 2 for 1 pools", %{user: user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]
      bk_1_h = ["vu", "sbe", "bk", ":year1", ":resit", ":2021"]

      Campaign.Context.update_pool_participations(user, [iba_1, bk_1_h], [])
      Campaign.Context.update_pool_participations(user, [], [iba_1, bk_1_h])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "update_pool_participations/3 remove 2 for 2 pools", %{user: user} do
      iba_1 = ["vu", "sbe", "iba", ":year1", ":2021"]
      bk_2_h = ["vu", "sbe", "bk", ":year2", ":resit", ":2021"]

      Campaign.Context.update_pool_participations(user, [iba_1, bk_2_h], [])
      Campaign.Context.update_pool_participations(user, [], [iba_1, bk_2_h])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Pool.Context.get_by_name!("vu_sbe_rpr_year2_2021", [:participants])
    end

    defp create_campaign(status, budget, schedule_start \\ nil, schedule_end \\ nil) do
      promotion = Factories.insert!(:promotion)

      pool = Factories.insert!(:pool, %{name: "test_pool"})

      submission =
        Factories.insert!(:submission, %{
          pool: pool,
          reward_value: 2,
          status: status,
          schedule_start: schedule_start,
          schedule_end: schedule_end,
          director: :campaign
        })

      crew = Factories.insert!(:crew)
      survey_tool = Factories.insert!(:survey_tool)

      experiment =
        Factories.insert!(:experiment, %{
          survey_tool: survey_tool,
          duration: "10",
          subject_count: 1
        })

      assignment =
        Factories.insert!(:assignment, %{
          budget: budget,
          experiment: experiment,
          crew: crew,
          director: :campaign
        })

      Factories.insert!(:campaign, %{
        assignment: assignment,
        promotion: promotion,
        submissions: [submission]
      })
    end

    defp create_task(crew, status, expired, minutes_ago) when is_boolean(expired) do
      Factories.insert!(:member, %{student: true})
      |> create_task(crew, status, expired, minutes_ago)
    end

    defp create_task(user, crew, status, expired, minutes_ago) when is_boolean(expired) do
      updated_at = naive_timestamp(minutes_ago)
      expire_at = naive_timestamp(-1)
      member = Factories.insert!(:crew_member, %{crew: crew, user: user})

      _task =
        Factories.insert!(:crew_task, %{
          crew: crew,
          member: member,
          status: status,
          expired: expired,
          expire_at: expire_at,
          updated_at: updated_at
        })
    end

    defp yesterday() do
      timestamp(-24 * 60)
    end

    defp tomorrow() do
      timestamp(24 * 60)
    end

    defp next_week() do
      timestamp(7 * 24 * 60)
    end

    defp timestamp(shift_minutes) do
      Timestamp.now()
      |> Timestamp.shift_minutes(shift_minutes)
    end

    defp naive_timestamp(shift_minutes) do
      timestamp(shift_minutes)
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)
    end
  end
end
