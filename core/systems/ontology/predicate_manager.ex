defmodule Systems.Ontology.PredicateManager do
  @moduledoc """
  Predicate creation and management functionality.

  Manages formal Subject-Predicate-Object relationships in the ontology
  with support for negation and validation.
  """

  alias Systems.Ontology
  alias Core.Authentication.Actor

  @doc """
  Creates a formal predicate relationship in the ontology.
  """
  def create_predicate(
        subject_id,
        predicate_type_id,
        object_id,
        negated?,
        %Actor{} = actor
      ) do
    # Get entity for the actor
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    # Validate that all concept IDs exist
    with {:ok, subject} <- get_concept(subject_id),
         {:ok, predicate_type} <- get_concept(predicate_type_id),
         {:ok, object} <- get_concept(object_id),
         :ok <- validate_predicate_structure(subject, predicate_type, object, negated?) do
      try do
        predicate = Ontology.Public.obtain_predicate(subject, predicate_type, object, negated?, entity)
        
        %{
          success: true,
          subject_id: subject_id,
          predicate_type_id: predicate_type_id,
          object_id: object_id,
          negated?: negated?,
          actor_id: actor.id,
          predicate_id: predicate.id,
          # Already existed
          created: false,
          message: "Predicate retrieved successfully",
          relationship: format_predicate_display(subject, predicate_type, object, negated?)
        }
      rescue
        error ->
          %{
            success: false,
            subject_id: subject_id,
            predicate_type_id: predicate_type_id,
            object_id: object_id,
            negated?: negated?,
            actor_id: actor.id,
            predicate_id: nil,
            error: "Failed to create predicate: #{inspect(error)}"
          }
      end
    else
      {:error, reason} ->
        %{
          success: false,
          subject_id: subject_id,
          predicate_type_id: predicate_type_id,
          object_id: object_id,
          negated?: negated?,
          actor_id: actor.id,
          predicate_id: nil,
          error: reason
        }
    end
  end

  @doc """
  Creates a predicate from extracted relationship data.
  """
  def create_predicate_from_extraction(relationship_data, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    # Ensure all concepts exist
    with {:ok, subject_id} <- ensure_concept_exists(relationship_data.subject, entity),
         {:ok, predicate_type_id} <- ensure_concept_exists(relationship_data.predicate, entity),
         {:ok, object_id} <- ensure_concept_exists(relationship_data.object, entity) do
      create_predicate(subject_id, predicate_type_id, object_id, false, actor)
    else
      {:error, reason} -> %{success: false, error: reason, actor_id: actor.id}
    end
  end

  @doc """
  Lists predicates associated with an actor.
  """
  def list_actor_predicates(%Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    predicates = Ontology.Public.list_predicates([entity], [:subject, :type, :object])

    %{
      success: true,
      actor_id: actor.id,
      predicates:
        Enum.map(predicates, fn predicate ->
          %{
            id: predicate.id,
            subject: predicate.subject.phrase,
            predicate: predicate.type.phrase,
            object: predicate.object.phrase,
            negated: predicate.type_negated?,
            relationship:
              format_predicate_display(
                predicate.subject,
                predicate.type,
                predicate.object,
                predicate.type_negated?
              ),
            created_at: predicate.inserted_at
          }
        end),
      total_count: length(predicates)
    }
  end

  @doc """
  Searches for predicates by subject, predicate type, or object.
  """
  def search_predicates(search_term, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    predicates = Ontology.Public.list_predicates([entity], [:subject, :type, :object])

    matching_predicates =
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
          String.contains?(String.downcase(predicate.object.phrase), String.downcase(search_term))

        subject_match or type_match or object_match
      end)

    %{
      success: true,
      search_term: search_term,
      actor_id: actor.id,
      predicates:
        Enum.map(matching_predicates, fn predicate ->
          %{
            id: predicate.id,
            subject: predicate.subject.phrase,
            predicate: predicate.type.phrase,
            object: predicate.object.phrase,
            negated: predicate.type_negated?,
            relationship:
              format_predicate_display(
                predicate.subject,
                predicate.type,
                predicate.object,
                predicate.type_negated?
              ),
            relevance_score: calculate_predicate_relevance(predicate, search_term)
          }
        end),
      total_matches: length(matching_predicates)
    }
  end

  # Private functions

  defp get_concept(concept_id) when is_integer(concept_id) do
    case Ontology.Public.get_concept(concept_id) do
      nil -> {:error, "Concept not found: #{concept_id}"}
      concept -> {:ok, concept}
    end
  end

  defp get_concept(concept_phrase) when is_binary(concept_phrase) do
    case Ontology.Public.get_concept(concept_phrase) do
      nil -> {:error, "Concept not found: #{concept_phrase}"}
      concept -> {:ok, concept}
    end
  end

  defp validate_predicate_structure(subject, predicate_type, object, _negated) do
    cond do
      subject.id == object.id ->
        {:error, "Subject and object cannot be the same concept"}

      String.length(predicate_type.phrase) < 2 ->
        {:error, "Predicate type phrase too short"}

      true ->
        :ok
    end
  end

  defp ensure_concept_exists(phrase, entity) do
    try do
      concept = Ontology.Public.obtain_concept!(phrase, entity)
      {:ok, concept.id}
    rescue
      error -> {:error, "Failed to create concept '#{phrase}': #{inspect(error)}"}
    end
  end

  defp format_predicate_display(subject, predicate_type, object, negated) do
    negation = if negated, do: "NOT ", else: ""
    "#{subject.phrase} #{negation}#{predicate_type.phrase} #{object.phrase}"
  end

  defp calculate_predicate_relevance(predicate, search_term) do
    search_lower = String.downcase(search_term)

    subject_score =
      if String.contains?(String.downcase(predicate.subject.phrase), search_lower),
        do: 30,
        else: 0

    type_score =
      if String.contains?(String.downcase(predicate.type.phrase), search_lower), do: 40, else: 0

    object_score =
      if String.contains?(String.downcase(predicate.object.phrase), search_lower), do: 30, else: 0

    subject_score + type_score + object_score
  end
end
