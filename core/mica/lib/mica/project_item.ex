defmodule Mica.ProjectItem do
  @moduledoc """
  A project item type: what a project item can hold. One module per type, listed
  by its system's `c:Mica.System.project_items/0`:

      defmodule Systems.Assignment.ProjectItem do
        use Mica.ProjectItem

        def type, do: "assignment"
        def schema, do: Systems.Assignment.Model
      end

  The type name is stored with every project item (`project_items.item_type`), so
  it never changes. It is unique in the composition, and `"none"` is reserved: it
  marks an item that holds nothing.

  Behaviour of a loaded target (tag, status, info) stays in the
  `Frameworks.Concept.Leaf` protocol.
  """

  @doc "The stored type name, for example `\"assignment\"`."
  @callback type() :: String.t()

  @doc "The target's Ecto schema."
  @callback schema() :: module()

  @reserved ["none"]

  @doc "Type names no item type may use: `\"none\"` marks an item that holds nothing."
  def reserved, do: @reserved

  defmacro __using__(_opts) do
    quote do
      @behaviour Mica.ProjectItem
    end
  end
end
