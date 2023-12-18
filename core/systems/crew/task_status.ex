defmodule Systems.Crew.TaskStatus do
  def values, do: [:pending, :declined, :completed, :accepted, :rejected]
end
