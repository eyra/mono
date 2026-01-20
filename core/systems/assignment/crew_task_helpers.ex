defmodule Systems.Assignment.CrewTaskHelpers do
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  @type socket :: Phoenix.LiveView.Socket.t()
  @callback handle_tool_completed(socket()) :: socket()
  @callback handle_tool_initialized(socket()) :: socket()

  def map_item({%{id: id, title: title, group: group, description: description}, task}) do
    %{id: id, title: title, description: description, group: group, status: task_status(task)}
  end

  def task_status(%{status: status}), do: status
  def task_status(_), do: :pending

  def get_icon({%{group: group}, _} = _work_item) when is_binary(group) do
    String.downcase(group)
  end

  def get_icon(_), do: nil

  def singleton?(%{assigns: %{work_items: work_items}}) do
    length(work_items) == 1
  end

  @doc """
  Builds work_items list from assignment for the given user.
  Each work_item is a tuple {workflow_item, task}.
  """
  def build_work_items(%{status: status, crew: crew} = assignment, user) do
    if Assignment.Public.tester?(assignment, user) or status == :online do
      member = Crew.Public.get_member(crew, user)
      build_work_items_for_member(assignment, member, user)
    else
      []
    end
  end

  defp build_work_items_for_member(%{workflow: workflow} = assignment, %{} = member, user) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member, user)})
  end

  defp build_work_items_for_member(_assignment, nil, _user), do: []

  defp get_or_create_task(item, %{crew: crew} = assignment, member, user) do
    identifier = Assignment.Private.task_identifier(assignment, item, member)

    if task = Crew.Public.get_task(crew, identifier) do
      task
    else
      Crew.Public.create_task!(crew, [user], identifier)
    end
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Assignment.CrewTaskHelpers

      import Systems.Assignment.CrewTaskHelpers
      import Systems.Assignment.Html

      alias Systems.Assignment
      alias Systems.Crew
      alias Systems.Workflow

      import Frameworks.Pixel.Line

      def update_participant(%{assigns: %{model: %{crew: crew}, current_user: user}} = socket) do
        # In case of an external panel, the participant id given by the panel should be forwarded to external systems
        participant =
          if participant = get_in(socket.assigns, [:panel_info, :participant]) do
            participant
          else
            %{public_id: participant} = Crew.Public.member(crew, user)
            participant
          end

        assign(socket, participant: participant)
      end

      # Consume :tool_completed event published by all ToolViews
      # (Feldspar, Manual, Instruction, Document, Graphite)
      def consume_event(%{name: :tool_completed}, socket) do
        {:stop, socket |> handle_tool_completed()}
      end

      def consume_event(%{name: :tool_initialized}, socket) do
        {:stop, socket |> handle_tool_initialized()}
      end

      def consume_event(
            %{name: :donate, payload: %{key: key, data: data}},
            %{assigns: %{work_item: {%{id: task, group: group}, _}}} = socket
          ) do
        {:continue,
         socket |> publish_event({:store, %{task: task, key: key, group: group, data: data}})}
      end

      # HTTP upload complete - blob stored, forward for delivery scheduling
      def consume_event(
            %{name: :blob_stored, payload: %{key: key, blob_id: blob_id}},
            %{assigns: %{work_item: {%{id: task, group: group}, _}}} = socket
          ) do
        {:stop,
         socket
         |> publish_event(
           {:deliver_blob, %{task: task, key: key, group: group, blob_id: blob_id}}
         )}
      end
    end
  end
end
