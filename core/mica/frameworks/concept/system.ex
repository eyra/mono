defmodule Frameworks.Concept.System do
  import Frameworks.Utility.Module

  def director(module), do: system_module(module, "Director")

  def presenter(module), do: system_module(module, "Presenter")

  # A module names its own system's namespace (`Next.Systems.Graphite.X`); a bare
  # system name (`:student`) is looked up in Mica and then in the SaaS.
  defp system_module(module, name) do
    case system_namespace(module) do
      nil -> module |> to_system() |> get(name)
      namespace -> Module.concat(namespace ++ [name])
    end
  end
end
