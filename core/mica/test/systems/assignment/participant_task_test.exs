defmodule Systems.Assignment.ParticipantTaskTest do
  @moduledoc """
  The `participant_task` the crew task views give a tool, which a Feldspar Tool gets in
  `live-init`. A Tool keys the state it saves in the browser with it, so it must be the
  same for one participant in one task and differ for anyone or anything else.
  """
  use Mica.DataCase

  alias Frameworks.Concept.LiveContext
  alias Mica.Repo
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  describe "CrewTaskHelpers.participant_task/1" do
    test "is the crew task id as a decimal string" do
      assert Assignment.CrewTaskHelpers.participant_task(%Crew.TaskModel{id: 81_234}) == "81234"
    end
  end

  describe "the crew task views" do
    setup do
      user = Factories.insert!(:member)
      assignment = feldspar_assignment(user)
      [item] = Workflow.Model.ordered_items(assignment.workflow)

      %{user: user, assignment: assignment, item: item}
    end

    # The workflow item is the same task for every participant
    test "participant_task/1 crashes on the workflow item instead of the crew task", %{
      item: item
    } do
      assert_raise FunctionClauseError, fn ->
        Assignment.CrewTaskHelpers.participant_task(item)
      end
    end

    test "the task list gives the participant's crew task id", %{
      user: user,
      assignment: assignment,
      item: item
    } do
      assert list_participant_task(assignment, user, item) ==
               crew_task_id(assignment, user, item)
    end

    test "the horizontal task list gives the participant's crew task id", %{
      user: user,
      assignment: assignment,
      item: %{id: item_id} = item
    } do
      vm = horizontal_view_model(assignment, user, %{task: item_id})

      assert participant_task(vm.tool_modal) == crew_task_id(assignment, user, item)
    end

    test "the single task view gives the participant's crew task id", %{
      user: user,
      assignment: assignment,
      item: item
    } do
      vm =
        Assignment.CrewTaskSingleViewBuilder.view_model(assignment, %{
          assignment_id: assignment.id,
          current_user: user,
          live_context: live_context(assignment, user, %{})
        })

      assert participant_task(vm.tool_view) == crew_task_id(assignment, user, item)
    end
  end

  describe "participant_task" do
    test "stays the same across a reload" do
      user = Factories.insert!(:member)
      assignment = feldspar_assignment(user)
      [item] = Workflow.Model.ordered_items(assignment.workflow)

      first = list_participant_task(assignment, user, item)
      reloaded = Repo.get!(Assignment.Model, assignment.id) |> preload()

      assert list_participant_task(reloaded, user, item) == first
    end

    test "differs between participants of a task" do
      user = Factories.insert!(:member)
      other = Factories.insert!(:member)
      assignment = feldspar_assignment(user)
      assignment = Assignment.Factories.add_participant(assignment, other) |> preload()
      [item] = Workflow.Model.ordered_items(assignment.workflow)

      refute list_participant_task(assignment, user, item) ==
               list_participant_task(assignment, other, item)
    end

    test "differs between the tasks of a participant" do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Assignment.Factories.add_participant(assignment, user) |> preload()
      [first, second] = Workflow.Model.ordered_items(assignment.workflow)

      refute list_participant_task(assignment, user, first) ==
               list_participant_task(assignment, user, second)
    end

    # As a copy of an assignment would: its own crew, with the same uploaded Tool
    test "differs between assignments that use the same Tool upload" do
      user = Factories.insert!(:member)
      assignment = feldspar_assignment(user)
      copy = feldspar_assignment(user)
      [item] = Workflow.Model.ordered_items(assignment.workflow)
      [copy_item] = Workflow.Model.ordered_items(copy.workflow)

      assert archive_ref(item) == archive_ref(copy_item)

      refute list_participant_task(assignment, user, item) ==
               list_participant_task(copy, user, copy_item)
    end
  end

  defp feldspar_assignment(user) do
    Assignment.Factories.create_assignment_with_feldspar_tool()
    |> Assignment.Factories.add_participant(user)
    |> preload()
  end

  defp preload(assignment) do
    Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)
  end

  defp list_participant_task(assignment, user, %{id: item_id}) do
    user_state = %{task: item_id}

    vm =
      Assignment.CrewTaskListViewBuilder.view_model(assignment, %{
        assignment_id: assignment.id,
        current_user: user,
        user_state: user_state,
        live_context: live_context(assignment, user, user_state)
      })

    participant_task(vm.tool_modal)
  end

  defp horizontal_view_model(assignment, user, user_state) do
    Assignment.CrewTaskHorizontalListViewBuilder.view_model(assignment, %{
      assignment_id: assignment.id,
      current_user: user,
      user_state: user_state,
      live_context: live_context(assignment, user, user_state)
    })
  end

  defp live_context(assignment, user, user_state) do
    LiveContext.new(%{
      assignment_id: assignment.id,
      current_user: user,
      timezone: "UTC",
      user_state: user_state,
      panel_info: nil
    })
  end

  defp participant_task(%{element: %{options: options}}) do
    %{participant_task: participant_task} = options[:live_context].data
    participant_task
  end

  defp participant_task(%{options: options}) do
    %{participant_task: participant_task} = options[:live_context].data
    participant_task
  end

  defp crew_task_id(%{crew: crew} = assignment, user, item) do
    member = Crew.Public.get_member(crew, user)
    identifier = Assignment.Private.task_identifier(assignment, item, member)
    %Crew.TaskModel{id: id} = Crew.Public.get_task(crew, identifier)
    Integer.to_string(id)
  end

  defp archive_ref(%{tool_ref: tool_ref}) do
    %{archive_ref: archive_ref} = Workflow.ToolRefModel.tool(tool_ref)
    archive_ref
  end
end
