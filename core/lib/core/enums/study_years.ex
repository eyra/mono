defmodule Core.Enums.StudyYears do
  @moduledoc """
    Defines study years supported by the studentpool app.
  """
  use Core.Enums.Base, {:study_years, [:first, :second]}
end
