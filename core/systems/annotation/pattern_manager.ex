defmodule Systems.Annotation.PatternManager do
  @moduledoc """
  Annotation pattern management and DSL processing.

  Manages YAML-based annotation patterns and provides functionality for
  creating annotations that conform to pattern specifications.
  """

  alias Systems.Annotation
  alias Systems.Ontology
  alias Core.Authentication.Actor

  @doc """
  Creates an annotation from a pattern with validation.
  """
  def create_from_pattern(pattern_name, statement, references, %Actor{} = actor)
      when is_binary(pattern_name) and is_binary(statement) and is_list(references) do
    with {:ok, pattern} <- load_pattern(pattern_name),
         {:ok, validated_statement} <- validate_statement(statement, pattern),
         {:ok, validated_refs} <- validate_references(references, pattern),
         {:ok, annotation} <-
           create_pattern_annotation(pattern, validated_statement, validated_refs, actor) do
      {:ok,
       %{
         success: true,
         annotation_id: annotation.id,
         pattern_applied: pattern_name,
         statement: validated_statement,
         references: validated_refs
       }}
    else
      {:error, reason} -> {:error, %{success: false, error: reason}}
    end
  end

  @doc """
  Loads and compiles a pattern from JSON.

  TODO: Replace with YAML support when YamlElixir dependency is added.
  """
  def load_pattern(nil), do: {:error, "Pattern not found: nil"}

  def load_pattern(pattern_name) do
    case Systems.Annotation.CorePatterns.get_pattern(pattern_name) do
      {:ok, pattern} ->
        {:ok, pattern}

      {:error, _} ->
        # Fallback to case-insensitive matching for compatibility
        case String.downcase(pattern_name) do
          "feedback pattern" ->
            {:ok,
             %{
               name: "Feedback Pattern",
               version: "1.0.0",
               description: "Generic AI feedback on human statements",
               statement_template: "AI Analysis: {analysis_content}",
               statement_validation: %{min_length: 20, max_length: 2000, required_fields: []},
               required_references: [],
               optional_references: [
                 %{
                   name: "analyzes",
                   description: "The annotation being analyzed",
                   target_types: ["annotation"],
                   cardinality: "exactly_one"
                 },
                 %{
                   name: "extracts",
                   description: "Concepts extracted",
                   target_types: ["concept"],
                   cardinality: "zero_or_more"
                 }
               ],
               metadata: %{category: "ai_interaction"}
             }}

          "response pattern" ->
            {:ok,
             %{
               name: "Response Pattern",
               version: "1.0.0",
               description: "Human response to AI feedback",
               statement_template: "{response_content}",
               statement_validation: %{min_length: 5, max_length: 1000, required_fields: []},
               required_references: [
                 %{
                   name: "responds_to",
                   description: "The feedback being responded to",
                   target_types: ["annotation"],
                   cardinality: "exactly_one"
                 }
               ],
               optional_references: [
                 %{
                   name: "discusses",
                   description: "Concepts being discussed",
                   target_types: ["concept", "predicate"],
                   cardinality: "zero_or_more"
                 }
               ],
               metadata: %{category: "human_interaction"}
             }}

          "statement pattern" ->
            {:ok,
             %{
               name: "Statement Pattern",
               version: "1.0.0",
               description: "Basic human statement for knowledge contribution",
               statement_template: "{statement_content}",
               statement_validation: %{min_length: 10, max_length: 5000, required_fields: []},
               required_references: [],
               optional_references: [
                 %{
                   name: "builds_on",
                   description: "Previous statements this builds upon",
                   target_types: ["annotation", "concept"],
                   cardinality: "zero_or_more"
                 },
                 %{
                   name: "cites",
                   description: "External sources",
                   target_types: ["resource"],
                   cardinality: "zero_or_more"
                 }
               ],
               metadata: %{category: "knowledge_contribution"}
             }}

          _ ->
            {:error, "Pattern not found: #{pattern_name}"}
        end
    end
  end

  @doc """
  Lists all available patterns.
  """
  def list_available_patterns do
    Systems.Annotation.CorePatterns.list_patterns()
    |> Enum.map(fn pattern ->
      %{name: pattern.name, description: pattern.description}
    end)
  end

  @doc """
  Validates a statement against pattern requirements.
  """
  def validate_statement(statement, pattern) do
    validation = pattern.statement_validation

    cond do
      is_nil(statement) ->
        {:error, "Statement cannot be nil"}

      String.length(statement) < validation.min_length ->
        {:error, "Statement too short (min: #{validation.min_length})"}

      String.length(statement) > validation.max_length ->
        {:error, "Statement too long (max: #{validation.max_length})"}

      true ->
        {:ok, statement}
    end
  end

  @doc """
  Validates references against pattern requirements.
  """
  def validate_references(references, pattern) do
    with :ok <- validate_required_references(references, pattern.required_references),
         :ok <- validate_optional_references(references, pattern.optional_references) do
      {:ok, references}
    end
  end

  # Private functions

  # TODO: YAML pattern compilation functions will be added when YamlElixir dependency is available

  defp validate_required_references(references, required_specs) when is_list(references) do
    # Check that all required reference types are present
    provided_types = Enum.map(references, & &1["type"]) |> MapSet.new()
    required_types = Enum.map(required_specs, & &1.name) |> MapSet.new()

    missing = MapSet.difference(required_types, provided_types)

    if MapSet.size(missing) > 0 do
      {:error, "Missing required references: #{Enum.join(missing, ", ")}"}
    else
      :ok
    end
  end

  defp validate_optional_references(_references, _optional_specs) do
    # For now, accept all optional references
    # TODO: Add validation for target types and cardinality
    :ok
  end

  defp create_pattern_annotation(pattern, statement, _references, actor) do
    # Get entity for the actor
    {:ok, entity} = Core.Authentication.obtain_entity(actor)

    # Get or create a type concept for this pattern
    type_concept = Ontology.Public.obtain_concept!(pattern.name, entity)

    # Create the annotation using the pattern type
    case Annotation.Public.insert_annotation(type_concept, statement, entity, [], []) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, changeset} ->
        {:error, "Failed to create annotation: #{inspect(changeset.errors)}"}
    end
  end
end
