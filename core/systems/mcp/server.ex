defmodule Systems.MCP.Server do
  @moduledoc """
  MCP server providing AI agents access to knowledge systems.

  Basic implementation for the Model Context Protocol interface.
  With proper Actor-based authentication.

  TODO: Replace with proper Hermes.Server implementation when dependency is added.
  """

  alias Systems.MCP.Auth

  @capabilities %{
    tools: %{
      "create_concepts" => %{
        description:
          "Create multiple concepts in the global knowledge commons (AI agent provides the concepts)",
        parameters: %{
          concepts: %{
            type: "array",
            required: true,
            description: "Array of concept objects with phrase and optional description"
          },
          source_statement: %{
            type: "string",
            required: false,
            description: "Original statement these concepts were extracted from"
          }
        }
      },
      "create_predicates" => %{
        description:
          "Create multiple predicates/relationships in the knowledge graph (AI agent provides the relationships)",
        parameters: %{
          predicates: %{
            type: "array",
            required: true,
            description: "Array of predicate objects with subject, predicate, object phrases"
          },
          source_statement: %{
            type: "string",
            required: false,
            description: "Original statement these predicates were extracted from"
          }
        }
      },
      "create_concept" => %{
        description: "Create or retrieve a concept in the global knowledge commons",
        parameters: %{
          phrase: %{
            type: "string",
            required: true,
            description: "Concept phrase (e.g., 'Machine Learning')"
          },
          description: %{type: "string", required: false, description: "Optional description"}
        }
      },
      "create_predicate" => %{
        description: "Create a relationship between concepts in the knowledge graph",
        parameters: %{
          subject_id: %{type: "integer", required: true, description: "Subject concept ID"},
          predicate_type_id: %{
            type: "integer",
            required: true,
            description: "Predicate type concept ID"
          },
          object_id: %{type: "integer", required: true, description: "Object concept ID"},
          negated: %{
            type: "boolean",
            required: false,
            description: "Whether relationship is negated"
          }
        }
      },
      "create_annotation" => %{
        description: "Create a structured annotation using predefined patterns",
        parameters: %{
          pattern_name: %{
            type: "string",
            required: true,
            description: "Pattern name (e.g., 'Feedback Pattern')"
          },
          statement: %{type: "string", required: true, description: "The annotation content"},
          references: %{type: "array", required: false, description: "Referenced entities"}
        }
      },
      "query_knowledge" => %{
        description: "Query the knowledge graph for concepts, predicates, and relationships",
        parameters: %{
          query_type: %{
            type: "string",
            required: true,
            description: "Type of query (concepts, predicates, annotations)"
          },
          search_term: %{type: "string", required: false, description: "Search term or phrase"},
          filters: %{type: "object", required: false, description: "Additional query filters"}
        }
      },
      "get_feedback_loop" => %{
        description: "Retrieve AI-human feedback interactions for an annotation",
        parameters: %{
          annotation_id: %{
            type: "integer",
            required: true,
            description: "Annotation ID to get feedback for"
          },
          include_responses: %{
            type: "boolean",
            required: false,
            description: "Include human responses"
          }
        }
      },
      "validate_pattern" => %{
        description: "Validate annotation content against a specific pattern",
        parameters: %{
          pattern_name: %{
            type: "string",
            required: true,
            description: "Pattern to validate against"
          },
          statement: %{type: "string", required: true, description: "Statement to validate"},
          references: %{type: "array", required: false, description: "Referenced entities"}
        }
      },
      "list_patterns" => %{
        description:
          "List all available annotation patterns that can be used for structured knowledge capture",
        parameters: %{
          category: %{type: "string", required: false, description: "Filter by pattern category"},
          domain: %{
            type: "string",
            required: false,
            description: "Filter by domain (e.g., 'research', 'legal')"
          }
        }
      }
    }
  }

  @doc """
  Get server capabilities for documentation and introspection.
  """
  def get_capabilities, do: @capabilities

  @doc """
  Initialize MCP server with actor authentication.
  """
  def initialize(params) do
    case Auth.authenticate_actor_from_params(params) do
      {:ok, actor} ->
        case Auth.ensure_mcp_authorized(actor) do
          :ok ->
            {:ok,
             %{
               capabilities: @capabilities,
               server_info: %{
                 name: "Knowledge System MCP Server",
                 version: "1.0.0"
               },
               actor: actor
             }}

          {:error, reason} ->
            {:error, Auth.mcp_auth_error(reason)}
        end

      {:error, reason} ->
        {:error, Auth.mcp_auth_error(reason)}
    end
  end

  @doc """
  Execute an MCP tool with authentication.
  """
  def call_tool(tool_name, params, frame) do
    Auth.with_auth(frame, fn actor ->
      case @capabilities.tools[tool_name] do
        nil ->
          {:error,
           %{
             error: %{
               code: "TOOL_NOT_FOUND",
               message: "Unknown tool: #{tool_name}"
             }
           }}

        tool_def ->
          case validate_params_against_schema(params, tool_def.parameters) do
            :ok ->
              execute_tool(tool_name, params, actor, frame)

            {:error, reason} ->
              {:error,
               %{
                 error: %{
                   code: "INVALID_PARAMS",
                   message: reason
                 }
               }}
          end
      end
    end)
  end

  # Private tool execution functions

  defp execute_tool("create_concepts", params, actor, _frame) do
    safe_execute(fn ->
      create_multiple_concepts(params["concepts"], params["source_statement"], actor)
    end)
  end

  defp execute_tool("create_predicates", params, actor, _frame) do
    safe_execute(fn ->
      create_multiple_predicates(params["predicates"], params["source_statement"], actor)
    end)
  end

  defp execute_tool("create_concept", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Ontology.ConceptManager.create_concept(
        params["phrase"],
        params["description"],
        actor
      )
    end)
  end

  defp execute_tool("create_predicate", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Ontology.PredicateManager.create_predicate(
        params["subject_id"],
        params["predicate_type_id"],
        params["object_id"],
        params["negated"] || false,
        actor
      )
    end)
  end

  defp execute_tool("create_annotation", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Annotation.PatternManager.create_from_pattern(
        params["pattern_name"],
        params["statement"],
        params["references"] || [],
        actor
      )
    end)
  end

  defp execute_tool("query_knowledge", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Onyx.KnowledgeQuerier.query_knowledge(
        params["query_type"],
        params["search_term"],
        params["filters"] || %{},
        actor
      )
    end)
  end

  defp execute_tool("get_feedback_loop", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Onyx.FeedbackOrchestrator.get_feedback_loop(
        params["annotation_id"],
        params["include_responses"] || false,
        actor
      )
    end)
  end

  defp execute_tool("validate_pattern", params, actor, _frame) do
    safe_execute(fn ->
      Systems.Annotation.PatternValidator.validate_against_pattern(
        params["pattern_name"],
        params["statement"],
        params["references"] || [],
        actor
      )
    end)
  end

  defp execute_tool("list_patterns", params, actor, _frame) do
    safe_execute(fn ->
      all_patterns = Systems.Annotation.PatternManager.list_available_patterns()

      filtered_patterns = filter_patterns_by_criteria(all_patterns, params)

      %{
        success: true,
        patterns:
          Enum.map(filtered_patterns, fn pattern ->
            %{
              name: pattern.name,
              version: pattern.version,
              description: pattern.description,
              category: get_in(pattern, [:metadata, :category]),
              domain: get_in(pattern, [:metadata, :domain]),
              priority: get_in(pattern, [:metadata, :priority]),
              statement_template: pattern.statement_template,
              required_references: pattern.required_references || [],
              optional_references: pattern.optional_references || []
            }
          end),
        total_count: length(filtered_patterns),
        actor_id: actor.id
      }
    end)
  end

  defp execute_tool(tool_name, _params, _actor, _frame) do
    {:error,
     %{
       error: %{
         code: "TOOL_NOT_FOUND",
         message: "Unknown tool: #{tool_name}"
       }
     }}
  end

  # Parameter validation

  defp validate_params_against_schema(params, parameter_schema) do
    missing_required = find_missing_required_params(params, parameter_schema)

    case missing_required do
      [] ->
        :ok

      missing ->
        {:error, "Missing required parameters: #{Enum.join(missing, ", ")}"}
    end
  end

  defp find_missing_required_params(params, parameter_schema) do
    parameter_schema
    |> Enum.filter(fn {_name, spec} -> spec[:required] == true end)
    |> Enum.map(fn {name, _spec} -> to_string(name) end)
    |> Enum.reject(fn param_name -> Map.has_key?(params, param_name) end)
  end

  # Pattern filtering helper

  defp filter_patterns_by_criteria(patterns, params) do
    patterns
    |> filter_by_category(params["category"])
    |> filter_by_domain(params["domain"])
  end

  defp filter_by_category(patterns, nil), do: patterns

  defp filter_by_category(patterns, category) do
    Enum.filter(patterns, fn pattern ->
      get_in(pattern, [:metadata, :category]) == category
    end)
  end

  defp filter_by_domain(patterns, nil), do: patterns

  defp filter_by_domain(patterns, domain) do
    Enum.filter(patterns, fn pattern ->
      get_in(pattern, [:metadata, :domain]) == domain
    end)
  end

  # Batch creation helpers

  defp create_multiple_concepts(concepts, source_statement, actor) do
    results =
      Enum.map(concepts, fn concept ->
        phrase = concept["phrase"] || concept[:phrase]
        description = concept["description"] || concept[:description]

        case Systems.Ontology.ConceptManager.create_concept(phrase, description, actor) do
          %{success: true} = result ->
            %{
              success: true,
              phrase: phrase,
              concept_id: result.concept_id,
              created: result.created
            }

          %{success: false} = result ->
            %{success: false, phrase: phrase, error: result.error}
        end
      end)

    successful = Enum.filter(results, & &1.success)
    failed = Enum.filter(results, &(not &1.success))

    %{
      success: true,
      total_concepts: length(concepts),
      successful_count: length(successful),
      failed_count: length(failed),
      results: results,
      source_statement: source_statement,
      actor_id: actor.id,
      message:
        "Processed #{length(concepts)} concepts: #{length(successful)} successful, #{length(failed)} failed"
    }
  end

  defp create_multiple_predicates(predicates, source_statement, actor) do
    results =
      Enum.map(predicates, fn predicate ->
        subject_phrase = predicate["subject"] || predicate[:subject]
        predicate_phrase = predicate["predicate"] || predicate[:predicate]
        object_phrase = predicate["object"] || predicate[:object]
        negated = predicate["negated"] || predicate[:negated] || false

        # First ensure the concepts exist
        with %{success: true, concept_id: subject_id} <-
               Systems.Ontology.ConceptManager.create_concept(subject_phrase, nil, actor),
             %{success: true, concept_id: predicate_id} <-
               Systems.Ontology.ConceptManager.create_concept(predicate_phrase, nil, actor),
             %{success: true, concept_id: object_id} <-
               Systems.Ontology.ConceptManager.create_concept(object_phrase, nil, actor) do
          case Systems.Ontology.PredicateManager.create_predicate(
                 subject_id,
                 predicate_id,
                 object_id,
                 negated,
                 actor
               ) do
            %{success: true} = result ->
              %{
                success: true,
                subject: subject_phrase,
                predicate: predicate_phrase,
                object: object_phrase,
                negated: negated,
                predicate_id: result.predicate_id
              }

            %{success: false} = result ->
              %{
                success: false,
                subject: subject_phrase,
                predicate: predicate_phrase,
                object: object_phrase,
                error: result.error
              }
          end
        else
          %{success: false, error: error} ->
            %{
              success: false,
              subject: subject_phrase,
              predicate: predicate_phrase,
              object: object_phrase,
              error: "Failed to create required concepts: #{error}"
            }
        end
      end)

    successful = Enum.filter(results, & &1.success)
    failed = Enum.filter(results, &(not &1.success))

    %{
      success: true,
      total_predicates: length(predicates),
      successful_count: length(successful),
      failed_count: length(failed),
      results: results,
      source_statement: source_statement,
      actor_id: actor.id,
      message:
        "Processed #{length(predicates)} predicates: #{length(successful)} successful, #{length(failed)} failed"
    }
  end

  # Enhanced error handling wrapper

  defp safe_execute(fun) do
    try do
      case fun.() do
        {:ok, result} ->
          {:ok, result}

        {:error, reason} ->
          {:error, %{error: %{code: "EXECUTION_ERROR", message: inspect(reason)}}}

        %{success: true} = result ->
          {:ok, result}

        %{success: false, error: error} ->
          {:error, %{error: %{code: "BUSINESS_ERROR", message: error}}}

        result ->
          {:ok, result}
      end
    rescue
      error ->
        {:error,
         %{
           error: %{
             code: "INTERNAL_ERROR",
             message: "Internal server error: #{inspect(error)}"
           }
         }}
    end
  end
end
