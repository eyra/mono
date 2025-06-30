defmodule Systems.Ontology.ConceptManager do
  @moduledoc """
  Concept creation and management functionality.

  Provides high-level functions for creating and managing ontology concepts
  with proper entity management and validation.
  """

  alias Systems.Ontology
  alias Core.Authentication.Actor

  @doc """
  Creates a new concept in the ontology.
  """
  def create_concept(phrase, description \\ nil, %Actor{} = actor) do
    # Get entity for the actor
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    # Validate phrase format (should be human-readable with spaces and capitals)
    case validate_concept_phrase(phrase) do
      {:ok, normalized_phrase} ->
        try do
          concept = Ontology.Public.obtain_concept!(normalized_phrase, entity)

          %{
            success: true,
            phrase: normalized_phrase,
            description: description,
            actor_id: actor.id,
            concept_id: concept.id,
            # Already existed
            created: false,
            message: "Concept retrieved successfully"
          }
        rescue
          error ->
            %{
              success: false,
              phrase: phrase,
              description: description,
              actor_id: actor.id,
              concept_id: nil,
              error: "Failed to create concept: #{inspect(error)}"
            }
        end

      {:error, reason} ->
        %{
          success: false,
          phrase: phrase,
          description: description,
          actor_id: actor.id,
          concept_id: nil,
          error: reason
        }
    end
  end

  @doc """
  Finds or creates a concept, ensuring it exists in the ontology.
  """
  def ensure_concept_exists(phrase, %Actor{} = actor) do
    case create_concept(phrase, nil, actor) do
      %{success: true, concept_id: id} -> {:ok, id}
      %{success: false, error: reason} -> {:error, reason}
    end
  end

  @doc """
  Lists concepts created by or associated with an actor.
  """
  def list_actor_concepts(%Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    concepts = Ontology.Public.list_concepts([entity], [])

    %{
      success: true,
      actor_id: actor.id,
      concepts:
        Enum.map(concepts, fn concept ->
          %{
            id: concept.id,
            phrase: concept.phrase,
            created_at: concept.inserted_at
          }
        end),
      total_count: length(concepts)
    }
  end

  @doc """
  Searches for concepts by phrase or partial phrase.
  """
  def search_concepts(search_term, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    # Basic search - in a real implementation this would use full-text search
    concepts = Ontology.Public.list_concepts([entity], [])

    matching_concepts =
      concepts
      |> Enum.filter(fn concept ->
        String.contains?(String.downcase(concept.phrase), String.downcase(search_term))
      end)

    %{
      success: true,
      search_term: search_term,
      actor_id: actor.id,
      concepts:
        Enum.map(matching_concepts, fn concept ->
          %{
            id: concept.id,
            phrase: concept.phrase,
            relevance_score: calculate_relevance(concept.phrase, search_term)
          }
        end),
      total_matches: length(matching_concepts)
    }
  end

  # Private functions

  defp validate_concept_phrase(phrase) do
    cond do
      String.length(phrase) < 2 ->
        {:error, "Concept phrase too short (minimum 2 characters)"}

      String.length(phrase) > 100 ->
        {:error, "Concept phrase too long (maximum 100 characters)"}

      String.match?(phrase, ~r/^\s+|\s+$/) ->
        {:error, "Concept phrase cannot start or end with whitespace"}

      String.match?(phrase, ~r/[^\w\s\-']/) ->
        {:error, "Concept phrase contains invalid characters"}

      true ->
        # Normalize the phrase to follow conventions
        normalized =
          phrase
          |> String.trim()
          # Normalize multiple spaces
          |> String.replace(~r/\s+/, " ")
          |> String.split(" ")
          |> Enum.map(&String.capitalize/1)
          |> Enum.join(" ")

        {:ok, normalized}
    end
  end

  defp calculate_relevance(concept_phrase, search_term) do
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
end
