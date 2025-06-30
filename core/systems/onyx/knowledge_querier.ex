defmodule Systems.Onyx.KnowledgeQuerier do
  @moduledoc """
  Knowledge graph querying functionality.

  Provides unified access to concepts, predicates, and annotations
  with search and filtering capabilities.
  """

  alias Systems.Ontology
  alias Systems.Annotation
  alias Core.Authentication.Actor

  @doc """
  Queries the knowledge graph for concepts, predicates, or annotations.
  """
  def query_knowledge(query_type, search_term, filters \\ %{}, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    case query_type do
      "concepts" -> query_concepts(search_term, filters, entity, actor)
      "predicates" -> query_predicates(search_term, filters, entity, actor)
      "annotations" -> query_annotations(search_term, filters, entity, actor)
      _ -> %{success: false, error: "Unknown query type: #{query_type}", actor_id: actor.id}
    end
  end

  @doc """
  Searches across all knowledge types.
  """
  def search_all(search_term, filters \\ %{}, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    concepts = query_concepts(search_term, filters, entity, actor)
    predicates = query_predicates(search_term, filters, entity, actor)
    annotations = query_annotations(search_term, filters, entity, actor)

    %{
      success: true,
      search_term: search_term,
      actor_id: actor.id,
      results: %{
        concepts: concepts.results,
        predicates: predicates.results,
        annotations: annotations.results
      },
      total_results:
        length(concepts.results) + length(predicates.results) + length(annotations.results)
    }
  end

  # Private query functions

  defp query_concepts(search_term, _filters, entity, actor) do
    concepts = Ontology.Public.list_concepts([entity], [])

    matching_concepts =
      if search_term do
        concepts
        |> Enum.filter(fn concept ->
          String.contains?(String.downcase(concept.phrase), String.downcase(search_term))
        end)
      else
        concepts
      end

    results =
      Enum.map(matching_concepts, fn concept ->
        %{
          id: concept.id,
          phrase: concept.phrase,
          type: "concept",
          created_at: concept.inserted_at,
          relevance: calculate_concept_relevance(concept.phrase, search_term)
        }
      end)
      |> Enum.sort_by(& &1.relevance, :desc)

    %{
      success: true,
      query_type: "concepts",
      search_term: search_term,
      actor_id: actor.id,
      results: results,
      total_count: length(results)
    }
  end

  defp query_predicates(search_term, _filters, entity, actor) do
    predicates = Ontology.Public.list_predicates([entity], [:subject, :type, :object])

    matching_predicates =
      if search_term do
        predicates
        |> Enum.filter(fn predicate ->
          subject_match =
            String.contains?(
              String.downcase(predicate.subject.phrase),
              String.downcase(search_term)
            )

          type_match =
            String.contains?(String.downcase(predicate.type.phrase), String.downcase(search_term))

          object_match =
            String.contains?(
              String.downcase(predicate.object.phrase),
              String.downcase(search_term)
            )

          subject_match or type_match or object_match
        end)
      else
        predicates
      end

    results =
      Enum.map(matching_predicates, fn predicate ->
        %{
          id: predicate.id,
          subject: predicate.subject.phrase,
          predicate: predicate.type.phrase,
          object: predicate.object.phrase,
          negated: predicate.type_negated?,
          type: "predicate",
          created_at: predicate.inserted_at
        }
      end)

    %{
      success: true,
      query_type: "predicates",
      search_term: search_term,
      actor_id: actor.id,
      results: results,
      total_count: length(results)
    }
  end

  defp query_annotations(search_term, _filters, entity, actor) do
    annotations = Annotation.Public.list_annotations([entity], [:type])

    matching_annotations =
      if search_term do
        annotations
        |> Enum.filter(fn annotation ->
          String.contains?(String.downcase(annotation.statement), String.downcase(search_term))
        end)
      else
        annotations
      end

    results =
      Enum.map(matching_annotations, fn annotation ->
        %{
          id: annotation.id,
          statement:
            String.slice(annotation.statement, 0, 100) <>
              if(String.length(annotation.statement) > 100, do: "...", else: ""),
          full_statement: annotation.statement,
          type: annotation.type.phrase,
          annotation_type: "annotation",
          created_at: annotation.inserted_at,
          relevance: calculate_text_relevance(annotation.statement, search_term)
        }
      end)
      |> Enum.sort_by(& &1.relevance, :desc)

    %{
      success: true,
      query_type: "annotations",
      search_term: search_term,
      actor_id: actor.id,
      results: results,
      total_count: length(results)
    }
  end

  defp calculate_concept_relevance(_concept_phrase, nil), do: 50

  defp calculate_concept_relevance(concept_phrase, search_term) do
    concept_lower = String.downcase(concept_phrase)
    search_lower = String.downcase(search_term)

    cond do
      concept_lower == search_lower -> 100
      String.starts_with?(concept_lower, search_lower) -> 90
      String.ends_with?(concept_lower, search_lower) -> 80
      String.contains?(concept_lower, search_lower) -> 70
      true -> 50
    end
  end

  defp calculate_text_relevance(_text, nil), do: 50

  defp calculate_text_relevance(text, search_term) do
    text_lower = String.downcase(text)
    search_lower = String.downcase(search_term)

    # Count occurrences
    occurrences =
      text_lower
      |> String.split(search_lower)
      |> length()
      |> Kernel.-(1)

    base_score = if String.contains?(text_lower, search_lower), do: 60, else: 30
    occurrence_bonus = min(occurrences * 10, 40)

    base_score + occurrence_bonus
  end
end
