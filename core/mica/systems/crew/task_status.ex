defmodule Systems.Crew.TaskStatus do
  use Mica.Enums.Base,
      {:crew_task_status, [:pending, :completed, :accepted, :rejected]}

  def finished_states, do: [:completed, :accepted, :rejected]
end
