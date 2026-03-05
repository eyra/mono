defmodule Systems.Pool.SubmissionStatus do
  @moduledoc false
  use Core.Enums.Base,
      {:submission_status, [:idle, :submitted, :accepted, :completed]}
end
