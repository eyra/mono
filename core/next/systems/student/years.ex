defmodule Systems.Student.Years do
  @moduledoc """
    Defines student years supported by the studentpool app.
  """
  use Core.Enums.Base, {:student_years, [:first, :second]}
end
