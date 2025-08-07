defmodule Systems.Zircon.Private do
  use Systems.Zircon.Constants

  alias Systems.Annotation
  alias Systems.Ontology

  def list_research_dimensions() do
    Ontology.Public.get_members_of_category(@research_dimension)
  end

  def list_research_frameworks() do
    Ontology.Public.get_members_of_category(@research_framework)
  end

  def get_definition(concept, entity) do
    Annotation.Public.get_most_recent_definition(concept, entity)
  end
end
