defmodule Systems.Campaign.ContextTest do
  use Core.DataCase

  describe "assignments" do
    alias Systems.{
      Campaign,
      Crew,
      Bookkeeping
    }

    alias Core.Factories
    alias CoreWeb.UI.Timestamp

    test "mark_expired_debug?/0 should mark 1 expired task in online campaign" do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 0 expired tasks in submitted campaign" do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:submitted)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in closed campaign" do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()
      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted, nil, schedule_end)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in scheduled campaign" do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in submitted campaign" do
      %{promotable_assignment: %{crew: crew}} = create_campaign(:submitted)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in closed campaign" do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()
      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted, nil, schedule_end)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in scheduled campaign" do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: true} = Crew.Context.get_task!(task.id)
    end

    test "reward_student/2 One transaction of one student" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew} = assignment} = create_campaign(:accepted)

      create_task(student, crew, :accepted, false, -31)

      Campaign.Context.reward_student(assignment, student)

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 1

      assert %{credit: 0, debit: 2} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student.id})
    end

    test "reward_student/2 Two transactions of one student" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted)

      create_task(student, crew1, :accepted, false, -31)
      create_task(student, crew2, :accepted, false, -31)

      Campaign.Context.reward_student(assignment1, student)
      Campaign.Context.reward_student(assignment2, student)

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})) ==
               2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 2

      assert %{credit: 0, debit: 4} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student.id})
    end

    test "reward_student/2 Two transactions of two students" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1} = assignment1} = create_campaign(:accepted)
      %{promotable_assignment: %{crew: crew2} = assignment2} = create_campaign(:accepted)

      create_task(student1, crew1, :accepted, false, -31)
      create_task(student1, crew2, :accepted, false, -31)
      create_task(student2, crew1, :accepted, false, -31)
      create_task(student2, crew2, :accepted, false, -31)

      Campaign.Context.reward_student(assignment1, student1)
      Campaign.Context.reward_student(assignment2, student1)
      Campaign.Context.reward_student(assignment1, student2)
      Campaign.Context.reward_student(assignment2, student2)

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student1.id})
             ) == 2

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student2.id})
             ) == 2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 4

      assert %{credit: 0, debit: 8} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student2.id})
    end

    test "reward_student/2 One transaction of one student (via signals)" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted)
      task = create_task(student, crew, :pending, false, -31)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task)

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 1

      assert %{credit: 0, debit: 2} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student.id})
    end

    test "reward_student/2 One transaction of one student failed: task already accepted (via signals)" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted)
      task = create_task(student, crew, :accepted, false, -31)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task)

      assert Enum.empty?(Bookkeeping.Context.account_query(["wallet"]))
      assert Enum.empty?(Bookkeeping.Context.account_query(["fund"]))

      assert Enum.empty?(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})
             )

      assert Enum.empty?(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"}))
    end

    test "reward_student/2 Multiple transactions of two students (via signals)" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1}} = create_campaign(:accepted)
      %{promotable_assignment: %{crew: crew2}} = create_campaign(:accepted)

      task1 = create_task(student1, crew1, :pending, false, -31)
      task2 = create_task(student1, crew2, :pending, false, -31)
      task3 = create_task(student2, crew1, :pending, false, -31)
      _task4 = create_task(student2, crew2, :pending, false, -31)

      # accept task should send signal to campaign to reward student
      Crew.Context.accept_task(task1)
      Crew.Context.accept_task(task2)
      Crew.Context.accept_task(task3)

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student1.id})
             ) == 2

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student2.id})
             ) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 3

      assert %{credit: 0, debit: 6} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student1.id})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student2.id})
    end

    test "sync_student_credits/0 One transaction of one student" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted)

      create_task(student, crew, :accepted, false, -31)

      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 1

      assert %{credit: 0, debit: 2} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student.id})
    end

    test "sync_student_credits/0 One transaction of one student (sync twice)" do
      student = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted)

      create_task(student, crew, :accepted, false, -31)

      Campaign.Context.sync_student_credits()
      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student.id})) ==
               1

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 1

      assert %{credit: 0, debit: 2} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student.id})
    end

    test "sync_student_credits/0 Two transactions of two students" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})

      %{promotable_assignment: %{crew: crew1}} = create_campaign(:accepted)
      %{promotable_assignment: %{crew: crew2}} = create_campaign(:accepted)

      create_task(student1, crew1, :accepted, false, -31)
      create_task(student1, crew2, :accepted, false, -31)
      create_task(student2, crew1, :accepted, false, -31)
      create_task(student2, crew2, :accepted, false, -31)

      Campaign.Context.sync_student_credits()

      assert Enum.count(Bookkeeping.Context.account_query(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Context.account_query(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student1.id})
             ) == 2

      assert Enum.count(
               Bookkeeping.Context.list_entries({:wallet, "sbe_year2_2021", student2.id})
             ) == 2

      assert Enum.count(Bookkeeping.Context.list_entries({:fund, "sbe_year2_2021"})) == 4

      assert %{credit: 0, debit: 8} = Bookkeeping.Context.balance({:fund, "sbe_year2_2021"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Context.balance({:wallet, "sbe_year2_2021", student2.id})
    end

    defp create_campaign(status, schedule_start \\ nil, schedule_end \\ nil) do
      promotion = Factories.insert!(:promotion)

      _submission =
        Factories.insert!(:submission, %{
          promotion: promotion,
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
        Factories.insert!(:assignment, %{experiment: experiment, crew: crew, director: :campaign})

      Factories.insert!(:campaign, %{assignment: assignment, promotion: promotion})
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
