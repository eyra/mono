defmodule Systems.Zircon.Screening.ToolView do
  use CoreWeb, :live_component
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper
  alias Systems.Zircon

  def update(%{tool: tool, user: user}, socket) do
    session = Zircon.Public.obtain_screening_session!(tool, user)

    {
      :ok,
      socket
      |> assign(tool: tool, user: user, session: session)
      |> assign_next_paper_id()
      |> assign_next_paper()
      |> assign_next_button()
    }
  end

  defp assign_next_button(socket) do
    next_button = %{
      action: %{type: :send, event: "next"},
      face: %{type: :primary, label: dgettext("eyra-zircon", "tool_view.button.next")}
    }

    socket |> assign(next_button: next_button)
  end

  defp assign_next_paper_id(
         %{assigns: %{session: %{agent_state: agent_state} = session}} = socket
       ) do
    {:ok, {agent_state, paper_id}} =
      Zircon.Config.screening_agent_module().next_paper(agent_state)

    {:ok, session} = Zircon.Public.update_screening_session(session, agent_state)
    socket |> assign(session: session, paper_id: paper_id)
  end

  defp assign_next_paper(%{assigns: %{paper_id: paper_id}} = socket) do
    paper = Paper.Public.get!(paper_id)
    socket |> assign(paper: paper)
  end

  defp mark_current_paper_as_screened(
         %{assigns: %{session: %{agent_state: agent_state} = session, paper_id: paper_id}} =
           socket
       ) do
    {:ok, agent_state} =
      Zircon.Config.screening_agent_module().update_paper(agent_state, paper_id, nil, nil)

    {:ok, session} = Zircon.Public.update_screening_session(session, agent_state)
    socket |> assign(session: session)
  end

  def handle_event("next", _params, socket) do
    {
      :noreply,
      socket
      |> mark_current_paper_as_screened()
      |> assign_next_paper_id()
      |> assign_next_paper()
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>Paper Screening {inspect(@session.identifier)}</div>
      <div :if={@session.invalidated_at}>Session is invalidated</div>
      <div>{@paper.title}</div>
      <div>{@paper.abstract}</div>
      <div class="flex flex-row">
        <Button.dynamic {@next_button} />
      </div>
    </div>
    """
  end
end
