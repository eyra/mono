defmodule Frameworks.Concept.ScreeningAgent do
  alias Systems.Ontology
  alias Systems.Annotation
  alias Systems.Paper

  @type internal_id :: String.t()
  @type session_id :: String.t()
  @type paper_id :: String.t()
  @type criterion_id :: String.t()
  @type reason :: String.t()

  @type review_attrs :: map()
  @type paper :: Paper.Model.t()
  @type annotation :: Annotation.Model.t()
  @type concept :: Ontology.ConceptModel.t()
  @type criterion :: annotation()
  @type label :: annotation()

  # State is managed by the Screening Agent implementation
  @type state :: map()

  @type decision :: :include | :exclude | :undecided

  @callback start(session_id, papers :: list(paper()), criteria :: list(criterion())) ::
              {:ok, state} | {:error, reason}
  @callback next_paper(state) :: {:ok, {state, paper_id()}} | {:error, reason}
  @callback update_paper(state, paper_id(), criterion_id(), label()) ::
              {:ok, state} | {:error, reason}
end
