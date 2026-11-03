defmodule Next.Systems.Student.Years do
  @moduledoc """
    Defines student years supported by the studentpool app.
  """
  use Mica.Enums.Base, {:student_years, [:first, :second]}
end
