defmodule Frameworks.Concept.System do
  import Frameworks.Utility.Module

  def director(module) do
    module
    |> to_system()
    |> get("Director")
  end

  def presenter(module) do
    module
    |> to_system()
    |> get("Presenter")
  end
end
