defprotocol Systems.Ontology.Element do
  @moduledoc """
  A protocol for elements in the knowledge graph.
  """

  @doc """
  Returns a list of subelements.
  """
  @spec flatten(t :: any()) :: list()
  def flatten(t)
end
