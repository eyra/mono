defmodule Systems.Pool.SubmissionStatus do
  use Core.Enums.Base,
      {:submission_status, [:idle, :submitted, :accepted, :completed]}
end
