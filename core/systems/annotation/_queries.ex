defmodule Systems.Annotation.Queries do
  use Core, :auth
  require Frameworks.Utility.Query

  import Ecto.Query, warn: true
  import Frameworks.Utility.Query, only: [build: 3]

  def annotation_query do
    from(a in Systems.Annotation.Model, as: :annotation)
  end

  def annotation_query_include(query, _, nil) do
    query
  end

  def annotation_query_include(query, :statement, statement) when is_binary(statement) do
    build(query, :annotation, [statement == ^statement])
  end

  def annotation_query_include(query, :author, %Systems.Account.User{} = user) do
    build(query, :annotation, author: [id == ^user.id])
  end

  def annotation_query_include(query, :type, %Systems.Ontology.ConceptModel{} = type) do
    build(query, :annotation, [type_id == ^type.id])
  end

  def annotation_query_include(query, :type, phrase) when is_binary(phrase) do
    build(query, :annotation, type: [phrase == ^phrase])
  end

  def annotation_query_include(query, :annotation_ref, true) do
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

  def annotation_query_include(
        query,
        :ontology_concept,
        %Systems.Ontology.ConceptModel{} = concept
      ) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept_id == ^concept.id
      ]
    )
  end

  def annotation_query_include(
        query,
        :ontology_concepts,
        %Systems.Ontology.ConceptModel{} = concept
      ) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept_id == ^concept.id
      ]
    )
  end

  def annotation_query_include(query, :ontology_concept, phrase) when is_binary(phrase) do
    build(query, :annotation_ref,
      ontology_ref: [
        concept: [
          phrase == ^phrase
        ]
      ]
    )
  end
end
