defmodule Systems.Zircon.Screening.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper
  alias Systems.Zircon

  @doc """
  Builds view model for Zircon Screening tool view.

  ## Parameters
  - tool: The Zircon Screening tool model
  - assigns: Contains current_user from CrewTaskContext
  """
  def view_model(tool, %{current_user: user}) do
    session = Zircon.Public.obtain_screening_session!(tool, user)
    {agent_state, paper_id} = get_next_paper_id(session)
    paper = Paper.Public.get!(paper_id)

    %{
      tool: tool,
      user: user,
      session: session,
      agent_state: agent_state,
      paper_id: paper_id,
      paper: paper,
      next_button: build_next_button()
    }
  end

  defp get_next_paper_id(%{agent_state: agent_state}) do
    {:ok, {new_agent_state, paper_id}} =
      Zircon.Config.screening_agent_module().next_paper(agent_state)

    {new_agent_state, paper_id}
  end

  defp build_next_button do
    %{
      action: %{type: :send, event: "next"},
      face: %{type: :primary, label: dgettext("eyra-zircon", "tool_view.button.next")}
    }
  end
end
