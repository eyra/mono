defmodule Systems.Onyx.FeedbackOrchestrator do
  @moduledoc """
  Human-AI feedback loop orchestration.

  Manages the complete feedback loop between humans and AI for
  knowledge refinement and concept validation.
  """

  alias Systems.Annotation
  alias Core.Authentication.Actor

  @doc """
  Gets the complete feedback loop for an annotation.

  Traces the chain of feedback from original statement through AI analysis
  to human responses and subsequent refinements.
  """
  def get_feedback_loop(annotation_id, include_responses \\ true, %Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    case Annotation.Public.get_annotation(annotation_id) do
      nil ->
        %{
          success: false,
          error: "Annotation not found",
          annotation_id: annotation_id,
          actor_id: actor.id
        }

      annotation ->
        feedback_chain = build_feedback_chain(annotation, include_responses, entity)

        %{
          success: true,
          annotation_id: annotation_id,
          include_responses: include_responses,
          actor_id: actor.id,
          original_annotation: format_annotation(annotation),
          feedback_chain: feedback_chain,
          chain_length: length(feedback_chain),
          status: determine_feedback_status(feedback_chain)
        }
    end
  end

  @doc """
  Creates a response to an AI feedback annotation.
  """
  def create_feedback_response(feedback_annotation_id, response_statement, %Actor{} = actor) do
    case Annotation.Public.get_annotation(feedback_annotation_id) do
      nil ->
        %{success: false, error: "Feedback annotation not found", actor_id: actor.id}

      _feedback_annotation ->
        # Create response annotation using Response Pattern
        references = [
          %{
            "type" => "responds_to",
            "target_id" => feedback_annotation_id,
            "target_type" => "annotation"
          }
        ]

        case Systems.Annotation.PatternManager.create_from_pattern(
               "Response Pattern",
               response_statement,
               references,
               actor
             ) do
          {:ok, result} ->
            %{
              success: true,
              response_annotation_id: result.annotation_id,
              feedback_annotation_id: feedback_annotation_id,
              actor_id: actor.id,
              statement: response_statement
            }

          {:error, reason} ->
            %{success: false, error: reason, actor_id: actor.id}
        end
    end
  end

  @doc """
  Gets statistics about feedback loop activity.
  """
  def get_feedback_statistics(%Actor{} = actor) do
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    annotations = Annotation.Public.list_annotations([entity], [:type])

    feedback_annotations =
      Enum.filter(annotations, fn ann ->
        ann.type.phrase == "Feedback Pattern"
      end)

    response_annotations =
      Enum.filter(annotations, fn ann ->
        ann.type.phrase == "Response Pattern"
      end)

    statement_annotations =
      Enum.filter(annotations, fn ann ->
        ann.type.phrase == "Statement Pattern"
      end)

    %{
      success: true,
      actor_id: actor.id,
      statistics: %{
        total_annotations: length(annotations),
        feedback_annotations: length(feedback_annotations),
        response_annotations: length(response_annotations),
        statement_annotations: length(statement_annotations),
        feedback_ratio:
          if(length(statement_annotations) > 0,
            do: length(feedback_annotations) / length(statement_annotations),
            else: 0
          ),
        response_ratio:
          if(length(feedback_annotations) > 0,
            do: length(response_annotations) / length(feedback_annotations),
            else: 0
          )
      }
    }
  end

  # Private functions

  defp build_feedback_chain(annotation, include_responses, entity) do
    # Find all annotations that reference this annotation
    related_annotations = find_related_annotations(annotation.id, entity)

    chain =
      related_annotations
      |> filter_by_response_inclusion(include_responses)
      |> sort_chronologically()
      |> Enum.map(&format_annotation/1)

    chain
  end

  defp find_related_annotations(_annotation_id, _entity) do
    # TODO: Implement actual reference traversal
    # This would query annotation_ref and annotation_assoc tables
    # to find annotations that reference the given annotation
    []
  end

  defp filter_by_response_inclusion(annotations, true), do: annotations

  defp filter_by_response_inclusion(annotations, false) do
    # Filter out response annotations, keep only AI feedback
    Enum.filter(annotations, fn ann ->
      ann.type.phrase != "Response Pattern"
    end)
  end

  defp sort_chronologically(annotations) do
    Enum.sort_by(annotations, & &1.inserted_at, :asc)
  end

  defp format_annotation(annotation) do
    %{
      id: annotation.id,
      statement: annotation.statement,
      type: annotation.type.phrase,
      created_at: annotation.inserted_at,
      entity_id: annotation.entity_id
    }
  end

  defp determine_feedback_status(feedback_chain) do
    case length(feedback_chain) do
      0 -> "no_feedback"
      1 -> "ai_feedback_provided"
      count when count >= 2 -> "human_response_received"
    end
  end
end
