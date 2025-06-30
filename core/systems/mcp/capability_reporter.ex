defmodule Systems.MCP.CapabilityReporter do
  @moduledoc """
  Utility module for reporting MCP server capabilities and generating documentation.

  Provides functions to help AI agents and developers understand what tools are
  available through the MCP server interface.
  """

  alias Systems.MCP.Server

  @doc """
  Generate a human-readable report of all MCP server capabilities.
  """
  def generate_capability_report do
    capabilities = get_server_capabilities()

    """
    # MCP Knowledge Server Capabilities

    ## Overview
    The MCP (Model Context Protocol) server provides AI agents with structured access to the platform's knowledge systems including concept extraction, predicate relationships, and annotation management.

    ## Authentication
    All tools require Actor-based authentication using API tokens. Actors must have MCP authorization permissions.

    ## Available Tools (#{map_size(capabilities.tools)})

    #{format_tools(capabilities.tools)}

    ## Usage Examples

    ### Create Concepts (AI Agent Provides Extracted Concepts)
    ```json
    {
      "tool": "create_concepts",
      "params": {
        "concepts": [
          {"phrase": "Machine Learning", "description": "AI technique for pattern recognition"},
          {"phrase": "Data Analysis", "description": "Process of examining data"},
          {"phrase": "Efficiency", "description": "Measure of performance"}
        ],
        "source_statement": "Machine learning improves data analysis efficiency"
      }
    }
    ```

    ### Create Predicates (AI Agent Provides Extracted Relationships)
    ```json
    {
      "tool": "create_predicates", 
      "params": {
        "predicates": [
          {"subject": "Machine Learning", "predicate": "Improves", "object": "Data Analysis"},
          {"subject": "Machine Learning", "predicate": "Enhances", "object": "Efficiency"}
        ],
        "source_statement": "Machine learning improves data analysis efficiency"
      }
    }
    ```

    ### Create Structured Annotations
    ```json
    {
      "tool": "create_annotation",
      "params": {
        "pattern_name": "Feedback Pattern",
        "statement": "AI Analysis: This statement discusses technological improvements",
        "references": []
      }
    }
    ```

    ### Discover Available Patterns
    ```json
    {
      "tool": "list_patterns",
      "params": {
        "category": "ai_interaction"
      }
    }
    ```

    ## Integration Notes
    - Global Knowledge Commons: Concepts and predicates are shared across all actors
    - Private Annotations: Annotation content remains actor-scoped for IP protection
    - Pattern-Based Structure: Use predefined patterns for consistent knowledge capture
    - Attribution Tracking: All knowledge contributions are attributed to the creating actor
    """
  end

  @doc """
  Get server capabilities in structured format.
  """
  def get_server_capabilities do
    Server.get_capabilities()
  end

  @doc """
  Get detailed information about a specific tool.
  """
  def get_tool_info(tool_name) do
    capabilities = get_server_capabilities()

    case capabilities.tools[tool_name] do
      nil ->
        {:error, "Tool not found: #{tool_name}"}

      tool_info ->
        {:ok,
         %{
           name: tool_name,
           description: tool_info.description,
           parameters: tool_info.parameters,
           required_params: get_required_params(tool_info.parameters),
           optional_params: get_optional_params(tool_info.parameters)
         }}
    end
  end

  @doc """
  List all available tool names.
  """
  def list_tool_names do
    capabilities = get_server_capabilities()
    Map.keys(capabilities.tools)
  end

  # Private helper functions

  defp format_tools(tools) do
    tools
    |> Enum.map(fn {name, info} ->
      format_tool(name, info)
    end)
    |> Enum.join("\n\n")
  end

  defp format_tool(name, info) do
    required_params = get_required_params(info.parameters)
    optional_params = get_optional_params(info.parameters)

    """
    ### #{name}
    **Description:** #{info.description}

    **Required Parameters:**
    #{format_params(required_params)}

    **Optional Parameters:**
    #{format_params(optional_params)}
    """
  end

  defp format_params([]), do: "_None_"

  defp format_params(params) do
    params
    |> Enum.map(fn {name, spec} ->
      "- `#{name}` (#{spec.type}): #{spec.description}"
    end)
    |> Enum.join("\n")
  end

  defp get_required_params(parameters) do
    parameters
    |> Enum.filter(fn {_name, spec} -> spec[:required] == true end)
  end

  defp get_optional_params(parameters) do
    parameters
    |> Enum.filter(fn {_name, spec} -> spec[:required] != true end)
  end
end
