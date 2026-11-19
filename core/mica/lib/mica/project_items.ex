defmodule Mica.ProjectItems do
  @moduledoc "The project item types of the composition (`c:Mica.System.project_items/0`)."

  @doc "The `Mica.ProjectItem` modules, in `c:Mica.SaaS.systems/0` order."
  def all, do: Mica.SaaS.project_items()

  @doc "The `Mica.ProjectItem` module of a type name, or `nil`."
  def get(type) when is_binary(type), do: Enum.find(all(), &(&1.type() == type))

  @doc "The `Mica.ProjectItem` module of a type name. Raises for a name the composition doesn't have."
  def fetch!(type) when is_binary(type) do
    get(type) || raise ArgumentError, "no project item type #{inspect(type)} in the composition"
  end

  @doc "The type name of a target struct or schema, or `nil` for a schema that is no item type."
  def type_of(%module{}), do: type_of(module)

  def type_of(schema) when is_atom(schema) do
    case Enum.find(all(), &(&1.schema() == schema)) do
      nil -> nil
      item -> item.type()
    end
  end
end
