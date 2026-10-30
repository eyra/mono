defmodule Systems.Pool.SubmissionStatus do
  use Mica.Enums.Base,
      {:submission_status, [:idle, :submitted, :accepted, :completed]}
end
