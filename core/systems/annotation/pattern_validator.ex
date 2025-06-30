defmodule Systems.Annotation.PatternValidator do
  @moduledoc """
  Annotation pattern validation functionality.

  Validates annotations against pattern specifications to ensure
  conformity with expected structure and content.
  """

  alias Systems.Annotation.PatternManager
  alias Core.Authentication.Actor

  @doc """
  Validates an annotation against a pattern specification.
  """
  def validate_against_pattern(pattern_name, statement, references \\ [], %Actor{} = actor) do
    with {:ok, pattern} <- PatternManager.load_pattern(pattern_name),
         {:ok, _} <- PatternManager.validate_statement(statement, pattern),
         {:ok, _} <- PatternManager.validate_references(references, pattern) do
      %{
        success: true,
        pattern_name: pattern_name,
        statement: statement,
        references: references,
        actor_id: actor.id,
        is_valid: true,
        validation_results: %{
          statement_valid: true,
          references_valid: true,
          pattern_version: pattern.version
        },
        suggestions: generate_suggestions(statement, references, pattern)
      }
    else
      {:error, reason} ->
        %{
          success: false,
          pattern_name: pattern_name,
          statement: statement,
          references: references,
          actor_id: actor.id,
          is_valid: false,
          validation_errors: [reason],
          suggestions: []
        }
    end
  end

  @doc """
  Validates an existing annotation against its pattern.
  """
  def validate_annotation(annotation, pattern_name \\ nil) do
    # Determine pattern name from annotation type or use provided name
    pattern_to_use = pattern_name || annotation.type.phrase

    # Extract references from annotation (this would need to be implemented)
    references = extract_annotation_references(annotation)

    validate_against_pattern(pattern_to_use, annotation.statement, references, %Actor{
      id: annotation.entity_id
    })
  end

  @doc """
  Suggests improvements for an annotation based on pattern requirements.
  """
  def suggest_improvements(statement, references, pattern_name) do
    with {:ok, pattern} <- PatternManager.load_pattern(pattern_name) do
      suggestions = []

      suggestions = suggestions ++ suggest_statement_improvements(statement, pattern)
      suggestions = suggestions ++ suggest_reference_improvements(references, pattern)

      %{success: true, suggestions: suggestions}
    else
      {:error, reason} -> %{success: false, error: reason}
    end
  end

  # Private functions

  defp generate_suggestions(statement, references, pattern) do
    suggestions = []

    # Check statement length optimality
    suggestions =
      if String.length(statement) < 50 and pattern.statement_validation.max_length > 100 do
        suggestions ++
          ["Consider adding more detail to your statement for better concept extraction"]
      else
        suggestions
      end

    # Check for missing optional references that might be useful
    if Enum.empty?(references) and not Enum.empty?(pattern.optional_references) do
      suggestions ++ ["Consider adding references to provide more context"]
    else
      suggestions
    end
  end

  defp suggest_statement_improvements(statement, pattern) do
    suggestions = []

    validation = pattern.statement_validation
    length = String.length(statement)

    cond do
      length < validation.min_length ->
        ["Statement is too short - add #{validation.min_length - length} more characters"]

      length > validation.max_length ->
        ["Statement is too long - reduce by #{length - validation.max_length} characters"]

      length < validation.min_length * 2 ->
        ["Consider adding more detail for better concept extraction"]

      true ->
        suggestions
    end
  end

  defp suggest_reference_improvements(references, pattern) do
    suggestions = []

    # Check for missing required references
    provided_types = Enum.map(references, & &1["type"]) |> MapSet.new()
    required_types = Enum.map(pattern.required_references, & &1.name) |> MapSet.new()
    missing = MapSet.difference(required_types, provided_types)

    if MapSet.size(missing) > 0 do
      suggestions ++ ["Add required references: #{Enum.join(missing, ", ")}"]
    else
      suggestions
    end
  end

  defp extract_annotation_references(_annotation) do
    # Basic implementation to extract references from annotation
    # In a full implementation, this would query the annotation_ref and annotation_assoc tables
    
    # For now, return empty list as placeholder
    # TODO: Implement full reference extraction when annotation reference system is complete
    []
  end
end
