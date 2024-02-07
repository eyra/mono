defmodule Systems.Crew.TaskStatus do
  def values, do: [:pending, :declined, :completed, :accepted, :rejected]

  def finished_states, do: [:declined, :completed, :accepted, :rejected]
end
