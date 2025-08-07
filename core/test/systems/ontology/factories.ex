defmodule Systems.Ontology.Factories do
  alias Core.Factories
  alias Systems.Ontology.ConceptModel
  alias Systems.Ontology.PredicateModel

  def insert_concept(phrase, %{} = author) do
    Factories.insert!(:ontology_concept, %{
      phrase: phrase,
      author: author
    })
  end

  def insert_predicate(%{} = subject, %{} = predicate, %{} = object, %{} = author) do
    Factories.insert!(:ontology_predicate, %{
      subject: subject,
      predicate: predicate,
      object: object,
      author: author
    })
  end

  def insert_ref(%ConceptModel{} = concept) do
    Factories.insert!(:ontology_ref, %{concept: concept})
  end

  def insert_ref(%PredicateModel{} = predicate) do
    Factories.insert!(:ontology_ref, %{predicate: predicate})
  end
end
