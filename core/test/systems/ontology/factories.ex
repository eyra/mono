defmodule Systems.Ontology.Factories do
  alias Core.Factories
  alias Systems.Ontology.ConceptModel
  alias Systems.Ontology.PredicateModel

  def insert_concept(phrase, %{} = author, opts \\ []) do
    ai_generated? = Keyword.get(opts, :ai_generated, false)

    Factories.insert!(:ontology_concept, %{
      phrase: phrase,
      author: author,
      ai_generated: ai_generated?
    })
  end

  def insert_predicate(%{} = subject, %{} = predicate, %{} = object, %{} = author, opts \\ []) do
    ai_generated? = Keyword.get(opts, :ai_generated, false)

    Factories.insert!(:ontology_predicate, %{
      subject: subject,
      predicate: predicate,
      object: object,
      author: author,
      ai_generated: ai_generated?
    })
  end

  def insert_ref(%ConceptModel{} = concept) do
    Factories.insert!(:ontology_ref, %{concept: concept})
  end

  def insert_ref(%PredicateModel{} = predicate) do
    Factories.insert!(:ontology_ref, %{predicate: predicate})
  end
end
