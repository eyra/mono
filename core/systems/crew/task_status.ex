defmodule Systems.Crew.TaskStatus do
  @moduledoc false
  use Core.Enums.Base,
      {:crew_task_status, [:pending, :completed, :accepted, :rejected]}

  def finished_states, do: [:completed, :accepted, :rejected]
end
