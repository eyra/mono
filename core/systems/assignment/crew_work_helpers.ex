defmodule Systems.Assignment.CrewWorkHelpers do
  alias Frameworks.Concept
  alias Systems.Crew
  alias Systems.Workflow

  @type socket :: Phoenix.LiveView.Socket.t()
  @callback handle_tool_exited(socket()) :: socket()
  @callback handle_tool_initialized(socket()) :: socket()

  def map_item({%{id: id, title: title, group: group, description: description}, task}) do
    %{id: id, title: title, description: description, icon: group, status: task_status(task)}
  end

  def task_status(%{status: status}), do: status
  def task_status(_), do: :pending

  def start_task(%{assigns: %{selected_item: {_, task}}} = socket) do
    start_task(socket, task)
  end

  def start_task(socket, task) do
    Crew.Public.start_task(task)
    socket
  end

  def launcher({%{tool_ref: tool_ref}, _}) do
    launcher(tool_ref)
  end

  def launcher(%Workflow.ToolRefModel{} = tool_ref) do
    tool_ref
    |> Workflow.ToolRefModel.tool()
    |> Concept.ToolModel.launcher()
  end

  def singleton?(%{assigns: %{work_items: work_items}}) do
    length(work_items) == 1
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Assignment.CrewWorkHelpers

      import Systems.Assignment.CrewWorkHelpers
      import Systems.Assignment.Html

      alias Systems.Assignment
      alias Systems.Crew
      alias Systems.Workflow

      import Frameworks.Pixel.Line

      def handle_task_completed(%{assigns: %{selected_item: {_, task}}} = socket) do
        {:ok, %{crew_task: updated_task}} = Crew.Public.complete_task(task)

        socket
        |> update_task(updated_task)
        |> send_event(:parent, "task_completed")
      end

      def update_task(%{assigns: %{work_items: work_items}} = socket, updated_task) do
        work_items =
          Enum.map(work_items, fn {item, task} ->
            if task.id == updated_task.id do
              {item, updated_task}
            else
              {item, task}
            end
          end)

        assign(socket, work_items: work_items)
      end

      def update_participant(%{assigns: %{crew: crew, user: user}} = socket) do
        # In case of an external panel, the particiant id given by the panel should be forwarded to external systems
        participant =
          if participant = get_in(socket.assigns, [:panel_info, :participant]) do
            participant
          else
            %{public_id: participant} = Crew.Public.member(crew, user)
          end

        assign(socket, participant: participant)
      end

      def handle_event("feldspar_event", event, socket) do
        {
          :noreply,
          socket |> handle_feldspar_event(event)
        }
      end

      defp handle_feldspar_event(
             socket,
             %{
               "__type__" => "CommandSystemExit",
               "code" => code,
               "info" => info
             }
           ) do
        if code == 0 do
          socket |> handle_tool_exited()
        else
          Frameworks.Pixel.Flash.put_info(
            socket,
            "Application stopped unexpectedly [#{code}]: #{info}"
          )
        end
      end

      defp handle_feldspar_event(
             %{assigns: %{selected_item: {%{id: task, group: group}, _}}} = socket,
             %{
               "__type__" => "CommandSystemDonate",
               "key" => key,
               "json_string" => json_string
             }
           ) do
        socket
        |> send_event(:root, "store", %{task: task, key: key, group: group, data: json_string})
        |> Frameworks.Pixel.Flash.put_info("Donated")
      end

      defp handle_feldspar_event(socket, %{
             "__type__" => "CommandSystemEvent",
             "name" => "initialized"
           }) do
        socket
        |> handle_tool_initialized()
      end

      defp handle_feldspar_event(socket, %{"__type__" => type}) do
        socket |> Frameworks.Pixel.Flash.put_error("Unsupported event " <> type)
      end

      defp handle_feldspar_event(socket, _) do
        socket |> Frameworks.Pixel.Flash.put_error("Unsupported event")
      end
    end
  end
end
