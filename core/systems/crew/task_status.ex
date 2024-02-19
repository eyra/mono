defmodule Systems.Crew.TaskStatus do
  def values, do: [:pending, :completed, :accepted, :rejected]

  def finished_states, do: [:completed, :accepted, :rejected]
end
