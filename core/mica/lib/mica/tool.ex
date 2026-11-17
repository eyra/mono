defmodule Mica.Tool do
  @moduledoc """
  A tool type: what a workflow item can hold. One module per type, listed by its
  system's `c:Mica.System.tools/0`:

      defmodule Systems.Feldspar.Tool do
        use Mica.Tool

        def type, do: "feldspar"
        def schema, do: Systems.Feldspar.ToolModel
        def prepare(attrs, %{auth_node: auth_node}), do: Systems.Feldspar.Public.prepare_tool(attrs, auth_node)
        def view, do: Systems.Feldspar.ToolView
      end

  The type name is stored with every reference to a tool (`tool_refs.tool_type`),
  so it never changes and never follows a module rename. It is unique in the
  composition, and `"none"` is reserved: it marks a reference to no tool.

  Behaviour of a loaded tool (labels, `ready?`, forms) stays in the
  `Frameworks.Concept.ToolModel` protocol, whose `key/1` equals `type/0`.
  """

  @typedoc "What `prepare/2` gets besides the attributes."
  @type context :: %{
          required(:auth_node) => struct(),
          optional(:user) => struct() | nil,
          optional(:director) => atom() | nil
        }

  @doc "The stored type name, for example `\"feldspar\"`."
  @callback type() :: String.t()

  @doc "The tool's Ecto schema."
  @callback schema() :: module()

  @doc "A changeset for a new tool of this type."
  @callback prepare(attrs :: map(), context()) :: Ecto.Changeset.t()

  @doc "The LiveView a participant works in, or `nil` when the tool has none."
  @callback view() :: module() | nil

  @reserved ["none"]

  @doc "Type names no tool may use: `\"none\"` marks a reference to no tool."
  def reserved, do: @reserved

  defmacro __using__(_opts) do
    quote do
      @behaviour Mica.Tool
    end
  end
end
