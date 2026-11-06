defmodule Next.Systems.Zircon.Screening.HumanAgent do
  @moduledoc """
  Human agent for the Zircon screening process.
  """

  @behaviour Next.Frameworks.Concept.ScreeningAgent

  @impl Next.Frameworks.Concept.ScreeningAgent
  def start(session_id, papers, _criteria) do
    paper_ids = Enum.map(papers, & &1.id)

    {:ok,
     %{
       "session_id" => session_id,
       "papers" => paper_ids,
       "screened_papers" => []
     }}
  end

  @impl Next.Frameworks.Concept.ScreeningAgent
  def next_paper(%{"screened_papers" => screened_papers, "papers" => papers} = state) do
    next_paper_id =
      Enum.find(papers, fn paper_id -> not Enum.member?(screened_papers, paper_id) end)

    {:ok, {state, next_paper_id}}
  end

  @impl Next.Frameworks.Concept.ScreeningAgent
  def update_paper(
        %{"screened_papers" => screened_papers} = state,
        paper_id,
        _criterion_id,
        _label
      ) do
    # We don't need to inform any AI about the decision, we just need to update the state
    if Enum.member?(screened_papers, paper_id) do
      {:error, :paper_already_screened}
    else
      {:ok, %{state | "screened_papers" => [paper_id | screened_papers]}}
    end
  end
end
