defmodule Systems.Crew.TaskStatus do
  def values, do: [:pending, :completed, :accepted, :rejected]
end
