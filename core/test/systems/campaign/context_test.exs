defmodule Systems.Campaign.ContextTest do
  use Core.DataCase

  describe "assignments" do
    alias Systems.{
      Campaign,
      Crew
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

    test "mark_expired_debug?/0 should mark 0 expired tasks in closed campaign" do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()
      %{promotable_assignment: %{crew: crew}} = create_campaign(:accepted, nil, schedule_end)
      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in scheduled campaign" do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug(true)

      assert %{expired: false} = Crew.Context.get_task!(task.id)
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

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 0 expired tasks in scheduled campaign" do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{promotable_assignment: %{crew: crew}} =
        create_campaign(:accepted, schedule_start, schedule_end)

      task = create_task(crew, :pending, false, -31)

      Campaign.Context.mark_expired_debug()

      assert %{expired: false} = Crew.Context.get_task!(task.id)
    end

    defp create_campaign(status, schedule_start \\ nil, schedule_end \\ nil) do
      promotion = Factories.insert!(:promotion)

      _submission =
        Factories.insert!(:submission, %{
          promotion: promotion,
          status: status,
          schedule_start: schedule_start,
          schedule_end: schedule_end
        })

      crew = Factories.insert!(:crew)
      survey_tool = Factories.insert!(:survey_tool)
      experiment = Factories.insert!(:experiment, %{survey_tool: survey_tool, duration: "10", subject_count: 1})
      assignment = Factories.insert!(:assignment, %{experiment: experiment, crew: crew})
      Factories.insert!(:campaign, %{assignment: assignment, promotion: promotion})
    end

    defp create_task(crew, status, expired, minutes_ago) when is_boolean(expired) do
      updated_at = naive_timestamp(minutes_ago)

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
