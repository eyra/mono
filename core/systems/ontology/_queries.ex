defmodule Systems.Ontology.Queries do
  import Ecto.Query
  require Frameworks.Utility.Query

  import Frameworks.Utility.Query, only: [build: 3]

  alias Core.Authentication
  alias Systems.Ontology

  # CONCEPT
  def concept_query() do
    from(c in Ontology.ConceptModel, as: :concept)
  end

  def concept_query(id) when is_integer(id) do
    build(concept_query(), :concept, [id == ^id])
  end

  def concept_query(phrase) when is_binary(phrase) do
    build(concept_query(), :concept, [phrase == ^phrase])
  end

  def concept_query(%Authentication.Entity{} = entity) do
    build(concept_query(), :concept, [entity_id == ^entity.id])
  end

  def concept_query_include(query, :entities, entities) do
    entity_ids = entities |> Enum.map(& &1.id)
    build(query, :concept, entity: [id in ^entity_ids])
  end

  def concept_query_include(query, :predicate, predicate) do
    concept_ids = [predicate.subject_id, predicate.type_id, predicate.object_id]
    build(query, :concept, id in ^concept_ids)
  end

  # PREDICATE

  def predicate_query() do
    from(p in Ontology.PredicateModel, as: :predicate)
  end

  def predicate_query({subject, type, object, type_negated?}) do
    build(predicate_query(), :predicate, [
      subject_id == ^subject.id,
      type_id == ^type.id,
      object_id == ^object.id,
      type_negated? == ^type_negated?
    ])
  end

  def predicate_query(%Ontology.ConceptModel{} = concept) do
    build(predicate_query(), :predicate, [
      subject_id == ^concept.id or
        type_id == ^concept.id or
        object_id == ^concept.id
    ])
  end

  def predicate_query(id) do
    build(predicate_query(), :predicate, id == ^id)
  end

  def predicate_query_include(query, :entities, entities) do
    entity_ids = entities |> Enum.map(& &1.id)
    build(query, :predicate, entity: [id in ^entity_ids])
  end

  # REF

  def ref_query() do
    from(r in Ontology.RefModel, as: :ref)
  end

  def ref_query({%Ontology.ConceptModel{} = concept, entities}) do
    concept_ids =
      concept_query(concept.id)
      |> concept_query_include(:entities, entities)
      |> select([concept: c], c.id)

    predicate_ids =
      predicate_query(concept)
      |> predicate_query_include(:entities, entities)
      |> select([predicate: p], p.id)

    build(
      ref_query(),
      :ref,
      concept_id in subquery(concept_ids) or predicate_id in subquery(predicate_ids)
    )
  end

  def ref_query(
        {%Ontology.PredicateModel{
           id: predicate_id,
           subject_id: subject_id,
           type_id: type_id,
           object_id: object_id
         }, _entities}
      ) do
    concept_ids = [subject_id, type_id, object_id]
    build(ref_query(), :ref, concept_id in ^concept_ids or predicate_id == ^predicate_id)
  end
end
