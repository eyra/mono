defmodule Systems.Assignment.CrewTaskHorizontalListViewBuilder do
  @moduledoc """
  The horizontal task list: one step per task, done in order. The current task
  is the first one that isn't finished, so a participant who comes back lands on
  it. Its intro shows below the steps; its start button opens the tool in the same
  modal as the vertical task list, through the participant's `user_state` task.
  """
  use Gettext, backend: MicaWeb.Gettext

  import Systems.Assignment.CrewTaskHelpers,
    only: [build_work_items: 2, get_participant: 3, recovery_context: 3]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Crew

  def view_model(
        %{crew: crew} = assignment,
        %{current_user: user, live_context: context} = assigns
      ) do
    work_items = build_work_items(assignment, user)
    current_index = Enum.find_index(work_items, &(not task_finished?(&1)))
    work_item = current_index && Enum.at(work_items, current_index)

    # Compute participant here to avoid timing issues (mount runs AFTER ViewBuilder)
    assignment_id = Map.get(assigns, :assignment_id)
    participant = get_participant(crew, user, assigns)

    context =
      LiveContext.extend(context, %{
        assignment_id: assignment_id,
        participant: participant,
        recovery: recovery_context(assignment, user, work_item)
      })

    %{
      steps: build_steps(work_items, current_index),
      work_item: work_item,
      intro: build_intro(work_item, current_index),
      tool_modal: build_tool_modal(work_item, Map.get(assigns, :user_state), context),
      finished?: finished?(assignment, user, work_items)
    }
  end

  # The participant's required tasks decide, as for every task view
  defp finished?(_assignment, _user, []), do: false

  defp finished?(%{crew: crew} = assignment, user, _work_items) do
    Assignment.Public.required_tasks_finished?(assignment, Crew.Public.get_member(crew, user))
  end

  defp task_finished?({_workflow_item, %{status: status}}),
    do: status in Crew.TaskStatus.finished_states()

  defp build_steps(work_items, current_index) do
    count = length(work_items)

    work_items
    |> Enum.with_index(1)
    |> Enum.map(fn {{%{id: id}, _task}, number} ->
      %{
        id: id,
        number: number,
        label: dgettext("eyra-assignment", "task_steps.step.label", index: number, count: count),
        status: step_status(number - 1, current_index)
      }
    end)
  end

  defp step_status(_index, nil), do: :complete
  defp step_status(index, current_index) when index < current_index, do: :complete
  defp step_status(index, current_index) when index == current_index, do: :current
  defp step_status(_index, _current_index), do: :incomplete

  defp build_intro({workflow_item, _task}, current_index) do
    %{title: title} = workflow_item

    %{
      number: current_index + 1,
      title: title,
      description: intro_description(workflow_item),
      button: %{
        action: %{type: :send, event: "start_task"},
        face: %{type: :primary, label: dgettext("eyra-assignment", "task_steps.start.button")},
        testid: "task-intro-start"
      }
    }
  end

  defp build_intro(nil, _current_index), do: nil

  # The researcher's description of the task, else the template's text for its tool
  defp intro_description(%{description: description})
       when is_binary(description) and description != "",
       do: description

  defp intro_description(%{tool_ref: %{special: special}}),
    do: Assignment.TemplateExtension.tool_description(special)

  # The tool opens in a modal once the participant starts the current task. Its intro
  # is on the page, so the tool starts without a start screen of its own.
  defp build_tool_modal({%{id: id} = workflow_item, _task}, %{task: id}, context) do
    %{tool_ref: tool_ref, title: title, group: icon} = workflow_item

    task_context =
      LiveContext.extend(context, %{
        workflow_item_id: id,
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        presentation: :modal,
        autostart: true
      })

    Assignment.ToolViewFactory.prepare_modal(tool_ref, task_context, "tool_modal")
  end

  defp build_tool_modal(_work_item, _user_state, _context), do: nil
end
