defmodule Systems.Assignment.RequiredTasksTest do
  use Mica.DataCase, async: false
  use Oban.Testing, repo: Mica.Repo

  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Monitor
  alias Systems.Workflow

  @data_donation_items [:manual, :donate, :questionnaire]

  describe "items added to a data donation workflow" do
    setup do
      items = [:manual, :request_manual, :download_manual, :donate, :questionnaire]
      %{assignment: Assignment.Factories.create_template_assignment(:data_donation, items)}
    end

    for special <- [:manual, :request_manual, :download_manual] do
      @special special
      test "a #{special} is not required", %{assignment: assignment} do
        assert %{required: false} = item(assignment, @special)
      end
    end

    for special <- [:donate, :questionnaire] do
      @special special
      test "a #{special} item is required", %{assignment: assignment} do
        assert %{required: true} = item(assignment, @special)
      end
    end
  end

  describe "items added to a questionnaire workflow" do
    test "a manual is required" do
      assignment = Assignment.Factories.create_template_assignment(:questionnaire, [:manual])
      assert %{required: true} = item(assignment, :manual)
    end
  end

  describe "finishing the required tasks of a data donation workflow" do
    setup do
      assignment =
        Assignment.Factories.create_template_assignment(:data_donation, @data_donation_items)

      participant = join_from_panel(assignment)
      complete(participant, :donate)
      complete(participant, :questionnaire)
      Map.put(participant, :assignment, assignment)
    end

    test "completes the participation without the manual", %{assignment: assignment, user: user} do
      assert %{completed_at: %NaiveDateTime{}} =
               Assignment.Public.get_participation(assignment, user)
    end

    test "queues one assignment_finished for the panel", %{user: user} do
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end

    test "counts the participant as finished in the Monitor", %{assignment: assignment} do
      assert 1 = finished_count(assignment)
    end

    test "leaves the manual open", %{tasks: tasks} do
      assert %{status: :pending} = Repo.reload!(tasks.manual)
    end
  end

  describe "marking the manual as done after finishing the required tasks" do
    setup do
      assignment =
        Assignment.Factories.create_template_assignment(:data_donation, @data_donation_items)

      participant = join_from_panel(assignment)
      complete(participant, :donate)
      complete(participant, :questionnaire)
      participation = Assignment.Public.get_participation(assignment, participant.user)
      finished_events = progress_events(participant.user, "assignment_finished")
      finished_count = finished_count(assignment)
      complete(participant, :manual)

      participant
      |> Map.put(:assignment, assignment)
      |> Map.put(:participation_before, participation)
      |> Map.put(:finished_events_before, finished_events)
      |> Map.put(:finished_count_before, finished_count)
    end

    test "queues the manual's task_finished", %{user: user} do
      assert ["task_finished", "task_finished", "task_finished"] =
               progress_events(user, "task_finished")
    end

    test "queues no second assignment_finished", %{
      user: user,
      finished_events_before: ["assignment_finished"]
    } do
      assert ["assignment_finished"] = progress_events(user, "assignment_finished")
    end

    test "leaves the participation unchanged", %{
      assignment: assignment,
      user: user,
      participation_before: %{completed_at: %NaiveDateTime{} = completed_at}
    } do
      assert %{completed_at: ^completed_at} =
               Assignment.Public.get_participation(assignment, user)
    end

    test "counts the participant once in the Monitor", %{
      assignment: assignment,
      finished_count_before: 1
    } do
      assert 1 = finished_count(assignment)
    end
  end

  describe "completing the last required task again" do
    test "queues no second assignment_finished" do
      assignment =
        Assignment.Factories.create_template_assignment(:data_donation, @data_donation_items)

      participant = join_from_panel(assignment)
      complete(participant, :donate)
      complete(participant, :questionnaire)

      {:ok, _} = Crew.Public.complete_task(Repo.reload!(participant.tasks.questionnaire))

      assert ["assignment_finished"] = progress_events(participant.user, "assignment_finished")
    end
  end

  describe "leaving the donation unfinished" do
    setup do
      assignment =
        Assignment.Factories.create_template_assignment(:data_donation, @data_donation_items)

      participant = join_from_panel(assignment)
      complete(participant, :manual)
      complete(participant, :questionnaire)
      Map.put(participant, :assignment, assignment)
    end

    test "leaves the participation incomplete", %{assignment: assignment, user: user} do
      refute match?(
               %{completed_at: %NaiveDateTime{}},
               Assignment.Public.get_participation(assignment, user)
             )
    end

    test "queues no assignment_finished", %{user: user} do
      assert [] = progress_events(user, "assignment_finished")
    end
  end

  describe "a data donation workflow with only a manual" do
    # Pending a product decision (SC-Port-03), all items count when none is required.
    setup do
      assignment = Assignment.Factories.create_template_assignment(:data_donation, [:manual])
      Map.put(join_from_panel(assignment), :assignment, assignment)
    end

    test "is not finished while the manual is open", %{assignment: assignment, member: member} do
      refute Assignment.Public.required_tasks_finished?(assignment, member)
    end

    test "is finished once the manual is done", %{assignment: assignment} = participant do
      complete(participant, :manual)
      assert Assignment.Public.required_tasks_finished?(assignment, participant.member)
    end
  end

  describe "an empty data donation workflow" do
    test "is never finished" do
      assignment = Assignment.Factories.create_template_assignment(:data_donation, [])
      %{member: member} = join_from_panel(assignment)
      refute Assignment.Public.required_tasks_finished?(assignment, member)
    end
  end

  describe "a questionnaire workflow with a manual" do
    setup do
      assignment =
        Assignment.Factories.create_template_assignment(:questionnaire, [:manual, :questionnaire])

      Map.put(join_from_panel(assignment), :assignment, assignment)
    end

    test "is not finished while the manual is open", %{assignment: assignment} = participant do
      complete(participant, :questionnaire)
      refute Assignment.Public.required_tasks_finished?(assignment, participant.member)
    end

    test "is finished once the manual is done too", %{assignment: assignment} = participant do
      complete(participant, :questionnaire)
      complete(participant, :manual)
      assert Assignment.Public.required_tasks_finished?(assignment, participant.member)
    end
  end

  describe "required_tasks_finished?/2 guards" do
    test "crashes without an assignment" do
      assert_raise FunctionClauseError, fn ->
        apply(Assignment.Public, :required_tasks_finished?, [nil, %Crew.MemberModel{}])
      end
    end

    test "is false without a member" do
      assignment = Assignment.Factories.create_template_assignment(:data_donation, [:donate])
      refute Assignment.Public.required_tasks_finished?(assignment, nil)
    end
  end

  describe "required_tasks_finished_by?/2 guards" do
    test "crashes without a task" do
      assignment = Assignment.Factories.create_template_assignment(:data_donation, [:donate])

      assert_raise FunctionClauseError, fn ->
        apply(Assignment.Public, :required_tasks_finished_by?, [assignment, nil])
      end
    end
  end

  describe "finish_if_required_tasks_finished/2 guards" do
    test "crashes without an assignment" do
      assert_raise FunctionClauseError, fn ->
        apply(Assignment.Public, :finish_if_required_tasks_finished, [nil, %Crew.MemberModel{}])
      end
    end

    test "does nothing without a member" do
      assignment = Assignment.Factories.create_template_assignment(:data_donation, [:donate])
      assert :ok = Assignment.Public.finish_if_required_tasks_finished(assignment, nil)
    end
  end

  describe "finish_if_required_tasks_finished/2" do
    setup do
      assignment =
        Assignment.Factories.create_template_assignment(:data_donation, @data_donation_items)

      Map.put(join_from_panel(assignment), :assignment, assignment)
    end

    test "does nothing while a required task is open", %{assignment: assignment} = participant do
      complete(participant, :donate)
      :ok = Assignment.Public.finish_if_required_tasks_finished(assignment, participant.member)
      assert [] = progress_events(participant.user, "assignment_finished")
    end

    test "does nothing for a member finished at their last required task",
         %{assignment: assignment} = participant do
      complete(participant, :donate)
      complete(participant, :questionnaire)
      :ok = Assignment.Public.finish_if_required_tasks_finished(assignment, participant.member)
      assert ["assignment_finished"] = progress_events(participant.user, "assignment_finished")
    end
  end

  defp item(%{workflow: %{id: workflow_id}}, special) do
    workflow_id
    |> Workflow.Public.list_items([:tool_ref])
    |> Enum.find(&(&1.tool_ref.special == special))
  end

  # A participant who entered through a panel link with a callback URL, with the task list
  # open, so each workflow item has its task.
  defp join_from_panel(%{affiliate: affiliate, crew: crew} = assignment) do
    affiliate =
      Repo.update!(Ecto.Changeset.change(affiliate, callback_url: "https://panel.example/cb"))

    %{user: user} = Factories.insert!(:affiliate_user, %{affiliate: affiliate, identifier: "p1"})
    {:ok, %{member: member}} = Assignment.Public.add_participant!(assignment, user)

    tasks =
      Map.new(Workflow.Public.list_items(assignment.workflow_id, [:tool_ref]), fn item ->
        identifier = Assignment.Private.task_identifier(assignment, item, member)
        {item.tool_ref.special, Crew.Public.create_task!(crew, [user], identifier)}
      end)

    %{user: user, member: member, tasks: tasks}
  end

  defp complete(%{tasks: tasks}, special) do
    {:ok, _} = Crew.Public.complete_task(Repo.reload!(Map.fetch!(tasks, special)))
  end

  defp progress_events(%{id: user_id}, progress) do
    for %{args: %{"user_id" => ^user_id, "event" => %{"progress" => ^progress}}} <-
          all_enqueued(worker: Affiliate.CallbackWorker),
        do: progress
  end

  defp finished_count(assignment) do
    Monitor.Public.event({assignment, :finished}) |> Monitor.Public.unique()
  end
end
