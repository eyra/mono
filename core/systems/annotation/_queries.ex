defmodule Systems.Annotation.Queries do
  use Core, :auth
  require Frameworks.Utility.Query

  import Ecto.Query, warn: true
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Ontology

  def annotation_query do
    from(a in Systems.Annotation.Model, as: :annotation)
  end

  def annotation_query_include(query, _, nil) do
    query
  end

  def annotation_query_include(query, :statement, statement) when is_binary(statement) do
    build(query, :annotation, [statement == ^statement])
  end

  def annotation_query_include(query, :entity, %Core.Authentication.Entity{} = entity) do
    annotation_query_include(query, :entities, [entity])
  end

  def annotation_query_include(query, :entities, entities) do
    entity_ids = entities |> Enum.map(& &1.id)
    build(query, :annotation, entity: [id in ^entity_ids])
  end

  def annotation_query_include(
        query,
        :reference,
        {%Systems.Annotation.Model{id: annotation_id}, _entities}
      ) do
    query
    |> where(
      [annotation: a, annotation_ref: ar],
      ar.annotation_id == ^annotation_id
    )
  end

  def annotation_query_include(
        query,
        :reference,
        {%Systems.Ontology.ConceptModel{id: concept_id} = concept, _entities}
      ) do
    ontology_ref_ids = Ontology.Public.query_ref_ids(concept)

    query
    |> annotation_query_join(:ontology_refs)
    |> where(
      [annotation: a, annotation_ref: ar, ontology_refs: orm],
      a.type_id == ^concept_id or
        ar.type_id == ^concept_id or
        orm.id in subquery(ontology_ref_ids)
    )
  end

  def annotation_query_include(
        query,
        :reference,
        {%Systems.Ontology.PredicateModel{id: predicate_id} = predicate, _entities}
      ) do
    ontology_ref_ids = Ontology.Public.query_ref_ids(predicate)

    query
    |> annotation_query_join(:ontology_refs)
    |> where(
      [annotation: a, annotation_ref: ar, ontology_refs: orm],
      a.type_id == ^predicate_id or
        ar.type_id == ^predicate_id or
        orm.id in subquery(ontology_ref_ids)
    )
  end

  def annotation_query_include(
        query,
        :reference,
        %Systems.Ontology.ConceptModel{} = concept
      ) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept_id == ^concept.id
      ]
    )
  end

  def annotation_query_include(query, :reference, {:concept, phrase}) when is_binary(phrase) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept: [
          phrase == ^phrase
        ]
      ]
    )
  end

  def annotation_query_include(query, :reference, {nil, _}) do
    query
  end

  def annotation_query_include(query, :type, %Systems.Ontology.ConceptModel{} = type) do
    build(query, :annotation, [type_id == ^type.id])
  end

  def annotation_query_include(query, :type, phrase) when is_binary(phrase) do
    build(query, :annotation, type: [phrase == ^phrase])
  end

  def annotation_query_include(query, :annotation, %Systems.Annotation.Model{} = annotation) do
    build(query, :annotation_ref, [annotation_id == ^annotation.id])
  end

  def annotation_query_include(
        query,
        :annotation_ref_type,
        %Systems.Ontology.ConceptModel{} = ref_type
      ) do
    build(query, :annotation_ref, [type_id == ^ref_type.id])
  end

  def annotation_query_include(query, :annotation_ref_type, phrase) when is_binary(phrase) do
    build(query, :annotation_ref, type: {:annotation_ref_type, [phrase == ^phrase]})
  end

  def annotation_query_join(query, :annotation_ref) do
    query
    |> join(:inner, [annotation: a], aa in Systems.Annotation.Assoc,
      on: aa.annotation_id == a.id,
      as: :annotation_assoc
    )
    |> join(:inner, [annotation_assoc: aa], ref in Systems.Annotation.RefModel,
      on: ref.id == aa.ref_id,
      as: :annotation_ref
    )
  end

  def annotation_query_join(query, :ontology_refs) do
    query
    |> join(:inner, [annotation_ref: ar], orm in Systems.Ontology.RefModel,
      on: orm.id == ar.ontology_ref_id,
      as: :ontology_refs
    )
  end

  def annotation_query_join(query, :ontology_concept) do
    query
    |> join(:inner, [ontology_refs: orm], oc in Systems.Ontology.ConceptModel,
      on: oc.id == orm.concept_id,
      as: :ontology_concept
    )
  end

  def annotation_query_join(query, :ontology_predicate) do
    query
    |> join(:inner, [ontology_refs: orm], op in Systems.Ontology.PredicateModel,
      on: op.id == orm.predicate_id,
      as: :ontology_predicate
    )
  end
end
