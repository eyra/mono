defmodule Systems.Workflow.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal
  alias Systems.Workflow

  def intercept({:manual_tool, _} = signal, %{manual_tool: tool} = message) do
    workflow_item = Workflow.Public.get_item_by_tool(tool, [:workflow, :tool_ref])

    dispatch!(
      {:workflow_item, signal},
      Map.merge(message, %{workflow_item: workflow_item})
    )

    :ok
  end

  @impl true
  def intercept(
        {:instruction_tool, _} = signal,
        %{instruction_tool: tool} = message
      ) do
    workflow_item = Workflow.Public.get_item_by_tool(tool, [:workflow, :tool_ref])

    dispatch!(
      {:workflow_item, signal},
      Map.merge(message, %{workflow_item: workflow_item})
    )

    :ok
  end

  @impl true
  def intercept(
        {:tool_ref, _} = signal,
        %{tool_ref: tool_ref} = message
      ) do
    workflow_item = Workflow.Public.get_item_by_tool_ref(tool_ref, [:workflow, :tool_ref])

    dispatch!(
      {:workflow_item, signal},
      Map.merge(message, %{workflow_item: workflow_item})
    )

    :ok
  end

  @impl true
  def intercept(
        {:workflow_item, _} = signal,
        %{workflow_item: %{workflow_id: workflow_id}} = message
      ) do
    workflow = Workflow.Public.get!(workflow_id)

    dispatch!(
      {:workflow, signal},
      Map.merge(message, %{workflow: workflow})
    )

    :ok
  end

  @impl true
  def intercept({:workflow, :rearranged} = signal, %{workflow_id: workflow_id} = message) do
    workflow = Workflow.Public.get!(workflow_id)

    dispatch!(
      {:workflow, signal},
      Map.merge(message, %{workflow: workflow})
    )

    :ok
  end
end
