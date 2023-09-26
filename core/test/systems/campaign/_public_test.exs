defmodule Systems.Campaign.PublicTest do
  use Core.DataCase

  describe "assignments" do
    alias Systems.{
      Campaign,
      Crew,
      Bookkeeping,
      Budget
    }

    alias CoreWeb.UI.Timestamp
    alias Core.Factories

    setup do
      currency = Budget.Factories.create_currency("fake_currency", :legal, "ƒ", 2)
      budget = Budget.Factories.create_budget("test", currency)
      user = Factories.insert!(:member)
      {:ok, currency: currency, budget: budget, user: user}
    end

    test "mark_expired_debug?/0 should mark 1 expired task in online campaign", %{
      budget: budget,
      user: user
    } do
      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 0 expired tasks in submitted campaign", %{
      budget: budget,
      user: user
    } do
      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :submitted, 1, budget)

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug()

      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in closed campaign", %{
      budget: budget,
      user: user
    } do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget, nil, schedule_end)

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in scheduled campaign", %{
      budget: budget,
      user: user
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(
          user,
          :accepted,
          1,
          budget,
          schedule_start,
          schedule_end
        )

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug(true)

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in submitted campaign", %{
      budget: budget,
      user: user
    } do
      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :submitted, 1, budget)

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug(true)

      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in closed campaign", %{
      budget: budget,
      user: user
    } do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget, nil, schedule_end)

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug(true)

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in scheduled campaign", %{
      budget: budget,
      user: user
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(
          user,
          :accepted,
          1,
          budget,
          schedule_start,
          schedule_end
        )

      task = Campaign.Factories.create_task(["task1"], crew, :pending, false, 31)

      Campaign.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "payout_participant/2 One transaction of one student", %{budget: budget, user: user} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student, crew, :accepted, false, 31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Public.payout_participant(assignment, student)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 Two transactions of one student", %{budget: budget, user: user} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      %{promotable_assignment: %{crew: crew2} = assignment2} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student, crew1, :accepted, false, 31)
      Campaign.Factories.create_task(["task2"], student, crew2, :accepted, false, 31)

      Budget.Factories.create_reward(assignment1, student, budget)
      Budget.Factories.create_reward(assignment2, student, budget)

      Campaign.Public.payout_participant(assignment1, student)
      Campaign.Public.payout_participant(assignment2, student)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 2

      assert %{credit: 10_000, debit: 5004} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 Two transactions of two students", %{budget: budget, user: user} do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      %{promotable_assignment: %{crew: crew2} = assignment2} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student1, crew1, :accepted, false, 31)
      Campaign.Factories.create_task(["task2"], student1, crew2, :accepted, false, 31)
      Campaign.Factories.create_task(["task3"], student2, crew1, :accepted, false, 31)
      Campaign.Factories.create_task(["task4"], student2, crew2, :accepted, false, 31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      Campaign.Public.payout_participant(assignment1, student1)
      Campaign.Public.payout_participant(assignment2, student1)
      Campaign.Public.payout_participant(assignment1, student2)
      Campaign.Public.payout_participant(assignment2, student2)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student2.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 4

      assert %{credit: 10_000, debit: 5008} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student2.id})
    end

    test "payout_participant/2 One transaction of one student (via signals)", %{
      budget: budget,
      user: user
    } do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      task = Campaign.Factories.create_task(["task1"], student, crew, :pending, false, 31)
      Budget.Factories.create_reward(assignment, student, budget)

      # accept task should send signal to campaign to reward student
      Crew.Public.accept_task(task)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student.id})
    end

    test "payout_participant/2 One transaction of one student failed: task already accepted (via signals)",
         %{budget: budget, user: user} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      task = Campaign.Factories.create_task(["task1"], student, crew, :accepted, false, 31)
      Budget.Factories.create_reward(assignment, student, budget)

      # accept task should send signal to campaign to reward student
      Crew.Public.accept_task(task)

      assert Enum.empty?(Bookkeeping.Public.list_accounts(["wallet"]))

      assert Enum.empty?(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id}))
    end

    test "payout_participant/2 Multiple transactions of two students (via signals)", %{
      budget: budget,
      user: user
    } do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      %{promotable_assignment: %{crew: crew2} = assignment2} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      task1 = Campaign.Factories.create_task(["task1"], student1, crew1, :pending, false, 31)
      task2 = Campaign.Factories.create_task(["task2"], student1, crew2, :pending, false, 31)
      task3 = Campaign.Factories.create_task(["task3"], student2, crew1, :pending, false, 31)
      _task4 = Campaign.Factories.create_task(["task4"], student2, crew2, :pending, false, 31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      # accept task should send signal to campaign to reward student
      Crew.Public.accept_task(task1)
      Crew.Public.accept_task(task2)
      Crew.Public.accept_task(task3)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student2.id})) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 3

      assert %{credit: 10_000, debit: 5006} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student2.id})
    end

    test "sync_student_credits/0 One transaction of one student", %{budget: budget, user: user} do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student, crew, :accepted, false, 31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Public.sync_student_credits()

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student.id})
    end

    test "sync_student_credits/0 One transaction of one student (sync twice -> no error)", %{
      budget: budget,
      user: user
    } do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student, crew, :accepted, false, 31)
      Budget.Factories.create_reward(assignment, student, budget)

      Campaign.Public.sync_student_credits()
      Campaign.Public.sync_student_credits()

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student.id})
    end

    test "sync_student_credits/0 Two transactions of two students", %{budget: budget, user: user} do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      %{promotable_assignment: %{crew: crew2} = assignment2} =
        Campaign.Factories.create_campaign(user, :accepted, 1, budget)

      Campaign.Factories.create_task(["task1"], student1, crew1, :accepted, false, 31)
      Campaign.Factories.create_task(["task2"], student1, crew2, :accepted, false, 31)
      Campaign.Factories.create_task(["task3"], student2, crew1, :accepted, false, 31)
      Campaign.Factories.create_task(["task4"], student2, crew2, :accepted, false, 31)

      Budget.Factories.create_reward(assignment1, student1, budget)
      Budget.Factories.create_reward(assignment2, student1, budget)
      Budget.Factories.create_reward(assignment1, student2, budget)
      Budget.Factories.create_reward(assignment2, student2, budget)

      Campaign.Public.sync_student_credits()

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student1.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:wallet, "fake_currency", student2.id})) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 4

      assert %{credit: 10_000, debit: 5008} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", student2.id})
    end

    defp yesterday() do
      Campaign.Factories.timestamp(-24 * 60)
    end

    defp tomorrow() do
      Campaign.Factories.timestamp(24 * 60)
    end

    defp next_week() do
      Campaign.Factories.timestamp(7 * 24 * 60)
    end
  end
end
