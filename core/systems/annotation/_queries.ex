defmodule Systems.Annotation.Queries do
  @moduledoc false
  use Core, :auth

  import Ecto.Query, warn: true
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Annotation.Model
  alias Systems.Ontology.ConceptModel
  alias Systems.Ontology.PredicateModel

  require Frameworks.Utility.Query

  def annotation_query do
    from(a in Model, as: :annotation)
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
    entity_ids = Enum.map(entities, & &1.id)
    build(query, :annotation, entity: [id in ^entity_ids])
  end

  def annotation_query_include(query, :reference, %Model{id: annotation_id}) do
    where(query, [annotation: a, annotation_ref: ar], ar.annotation_id == ^annotation_id)
  end

  def annotation_query_include(query, :reference, %PredicateModel{id: predicate_id}) do
    build(query, :annotation_ref,
      ontology_ref: [
        predicate_id == ^predicate_id
      ]
    )
  end

  def annotation_query_include(query, :reference, %ConceptModel{id: concept_id}) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept_id == ^concept_id
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

  def annotation_query_include(query, :type, %ConceptModel{} = type) do
    build(query, :annotation, [type_id == ^type.id])
  end

  def annotation_query_include(query, :type, phrase) when is_binary(phrase) do
    build(query, :annotation, type: [phrase == ^phrase])
  end

  def annotation_query_include(query, :annotation, %Model{} = annotation) do
    build(query, :annotation_ref, [annotation_id == ^annotation.id])
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
    join(query, :inner, [annotation_ref: ar], orm in Systems.Ontology.RefModel,
      on: orm.id == ar.ontology_ref_id,
      as: :ontology_refs
    )
  end

  def annotation_query_join(query, :ontology_concept) do
    join(query, :inner, [ontology_refs: orm], oc in ConceptModel, on: oc.id == orm.concept_id, as: :ontology_concept)
  end

  def annotation_query_join(query, :ontology_predicate) do
    join(query, :inner, [ontology_refs: orm], op in PredicateModel,
      on: op.id == orm.predicate_id,
      as: :ontology_predicate
    )
  end
end
