defmodule Systems.Zircon.Screening.ToolView do
  use CoreWeb, :modal_live_view
  use Frameworks.Pixel

  alias Systems.Paper
  alias Systems.Workflow
  alias Systems.Zircon

  def dependencies(), do: [:tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("next", _params, %{assigns: %{vm: vm}} = socket) do
    socket = mark_current_paper_as_screened_and_advance(socket, vm)
    {:noreply, socket}
  end

  defp mark_current_paper_as_screened_and_advance(
         socket,
         %{session: session, agent_state: agent_state, paper_id: paper_id}
       ) do
    # Mark current paper as screened
    {:ok, updated_agent_state} =
      Zircon.Config.screening_agent_module().update_paper(agent_state, paper_id, nil, nil)

    {:ok, updated_session} = Zircon.Public.update_screening_session(session, updated_agent_state)

    # Get next paper
    {:ok, {new_agent_state, new_paper_id}} =
      Zircon.Config.screening_agent_module().next_paper(updated_agent_state)

    {:ok, final_session} =
      Zircon.Public.update_screening_session(updated_session, new_agent_state)

    new_paper = Paper.Public.get!(new_paper_id)

    # Update view model with new state
    socket
    |> assign(
      vm: %{
        socket.assigns.vm
        | session: final_session,
          agent_state: new_agent_state,
          paper_id: new_paper_id,
          paper: new_paper
      }
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>Paper Screening {inspect(@vm.session.identifier)}</div>
      <div :if={@vm.session.invalidated_at}>Session is invalidated</div>
      <div>{@vm.paper.title}</div>
      <div>{@vm.paper.abstract}</div>
      <div class="flex flex-row">
        <Button.dynamic {@vm.next_button} />
      </div>
    </div>
    """
  end
end
