defmodule Systems.Annotation.PatternDSL do
  @moduledoc """
  Domain-Specific Language for defining annotation patterns using Elixir macros.

  This module provides a clean, declarative syntax for defining annotation patterns
  that can be used throughout the system for consistent knowledge structure.

  ## Example Usage

      defmodule MyPatterns do
        use Systems.Annotation.PatternDSL
        
        defpattern "Feedback Pattern" do
          version "1.0.0"
          description "Generic AI feedback on human statements"
          
          statement do
            template "AI Analysis: {analysis_content}"
            min_length 20
            max_length 2000
          end
          
          optional_reference "analyzes" do
            description "The annotation being analyzed"
            target_types ["annotation"]
            cardinality :exactly_one
          end
          
          optional_reference "extracts" do
            description "Concepts extracted"
            target_types ["concept"]
            cardinality :zero_or_more
          end
          
          metadata category: "ai_interaction"
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Systems.Annotation.PatternDSL
      @patterns []
      @before_compile Systems.Annotation.PatternDSL
    end
  end

  defmacro __before_compile__(env) do
    patterns = Module.get_attribute(env.module, :patterns)

    quote do
      def list_patterns, do: unquote(Macro.escape(patterns))

      def get_pattern(name) do
        case Enum.find(unquote(Macro.escape(patterns)), &(&1.name == name)) do
          nil -> {:error, "Pattern not found: #{name}"}
          pattern -> {:ok, pattern}
        end
      end
    end
  end

  @doc """
  Defines a new annotation pattern.

  ## Example

      defpattern "My Pattern" do
        version "1.0.0"
        description "Pattern description"
        
        statement do
          template "Template with {variables}"
          min_length 10
          max_length 500
        end
        
        required_reference "ref_name" do
          description "Reference description"
          target_types ["annotation", "concept"]
          cardinality :exactly_one
        end
      end
  """
  defmacro defpattern(name, do: block) do
    quote do
      @pattern_name unquote(name)
      @pattern_version "1.0.0"
      @pattern_description ""
      @pattern_statement %{}
      @pattern_required_refs []
      @pattern_optional_refs []
      @pattern_metadata %{}

      unquote(block)

      pattern = %{
        name: @pattern_name,
        version: @pattern_version,
        description: @pattern_description,
        statement_template: Map.get(@pattern_statement, :template, ""),
        statement_validation: %{
          min_length: Map.get(@pattern_statement, :min_length, 1),
          max_length: Map.get(@pattern_statement, :max_length, 10000),
          required_fields: Map.get(@pattern_statement, :required_fields, [])
        },
        required_references: @pattern_required_refs,
        optional_references: @pattern_optional_refs,
        metadata: @pattern_metadata
      }

      @patterns [pattern | @patterns]
    end
  end

  @doc """
  Sets the version for the current pattern.
  """
  defmacro version(version_string) do
    quote do
      @pattern_version unquote(version_string)
    end
  end

  @doc """
  Sets the description for the current pattern.
  """
  defmacro description(desc) do
    quote do
      @pattern_description unquote(desc)
    end
  end

  @doc """
  Defines statement configuration for the pattern.

  ## Example

      statement do
        template "AI Analysis: {content}"
        min_length 20
        max_length 1000
        required_fields ["content"]
      end
  """
  defmacro statement(do: block) do
    quote do
      @pattern_statement %{}
      unquote(block)
    end
  end

  @doc """
  Sets the template for statements in this pattern.
  """
  defmacro template(template_string) do
    quote do
      @pattern_statement Map.put(@pattern_statement, :template, unquote(template_string))
    end
  end

  @doc """
  Sets the minimum length for statements.
  """
  defmacro min_length(length) do
    quote do
      @pattern_statement Map.put(@pattern_statement, :min_length, unquote(length))
    end
  end

  @doc """
  Sets the maximum length for statements.
  """
  defmacro max_length(length) do
    quote do
      @pattern_statement Map.put(@pattern_statement, :max_length, unquote(length))
    end
  end

  @doc """
  Sets required fields for statement validation.
  """
  defmacro required_fields(fields) when is_list(fields) do
    quote do
      @pattern_statement Map.put(@pattern_statement, :required_fields, unquote(fields))
    end
  end

  @doc """
  Defines a required reference for the pattern.

  ## Example

      required_reference "analyzes" do
        description "The annotation being analyzed"
        target_types ["annotation"]
        cardinality :exactly_one
      end
  """
  defmacro required_reference(name, do: block) do
    quote do
      @ref_name unquote(name)
      @ref_description ""
      @ref_target_types []
      @ref_cardinality :zero_or_more

      unquote(block)

      ref_spec = %{
        name: @ref_name,
        description: @ref_description,
        target_types: @ref_target_types,
        cardinality: @ref_cardinality
      }

      @pattern_required_refs [@pattern_required_refs, ref_spec] |> List.flatten()
    end
  end

  @doc """
  Defines an optional reference for the pattern.
  """
  defmacro optional_reference(name, do: block) do
    quote do
      @ref_name unquote(name)
      @ref_description ""
      @ref_target_types []
      @ref_cardinality :zero_or_more

      unquote(block)

      ref_spec = %{
        name: @ref_name,
        description: @ref_description,
        target_types: @ref_target_types,
        cardinality: @ref_cardinality
      }

      @pattern_optional_refs [@pattern_optional_refs, ref_spec] |> List.flatten()
    end
  end

  @doc """
  Sets the description for the current reference.
  """
  defmacro ref_description(desc) do
    quote do
      @ref_description unquote(desc)
    end
  end

  @doc """
  Sets the target types for the current reference.
  """
  defmacro target_types(types) when is_list(types) do
    quote do
      @ref_target_types unquote(types)
    end
  end

  @doc """
  Sets the cardinality for the current reference.

  Valid values: :zero_or_more, :one_or_more, :exactly_one, :zero_or_one
  """
  defmacro cardinality(card)
           when card in [:zero_or_more, :one_or_more, :exactly_one, :zero_or_one] do
    quote do
      @ref_cardinality unquote(card)
    end
  end

  @doc """
  Sets metadata for the pattern.

  ## Example

      metadata category: "ai_interaction", priority: "high"
  """
  defmacro metadata(keyword_list) when is_list(keyword_list) do
    quote do
      @pattern_metadata Map.merge(@pattern_metadata, Enum.into(unquote(keyword_list), %{}))
    end
  end
end
