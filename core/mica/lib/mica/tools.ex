defmodule Mica.Tools do
  @moduledoc "The tool types of the composition (`c:Mica.System.tools/0`)."

  @doc "The `Mica.Tool` modules, in `c:Mica.SaaS.systems/0` order."
  def all, do: Mica.SaaS.tools()

  @doc "The `Mica.Tool` module of a type name, or `nil`."
  def get(type) when is_binary(type), do: Enum.find(all(), &(&1.type() == type))

  @doc "The `Mica.Tool` module of a type name. Raises for a name the composition doesn't have."
  def fetch!(type) when is_binary(type) do
    get(type) || raise ArgumentError, "no tool type #{inspect(type)} in the composition"
  end

  @doc "The type name of a tool struct or schema, or `nil` for a schema that is no tool."
  def type_of(%module{}), do: type_of(module)

  def type_of(schema) when is_atom(schema) do
    case Enum.find(all(), &(&1.schema() == schema)) do
      nil -> nil
      tool -> tool.type()
    end
  end
end
