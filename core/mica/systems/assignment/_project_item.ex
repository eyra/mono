defmodule Systems.Assignment.ProjectItem do
  @moduledoc "The `assignment` project item type (`Mica.ProjectItem`)."
  use Mica.ProjectItem

  @impl true
  def type, do: "assignment"

  @impl true
  def schema, do: Systems.Assignment.Model
end
