defmodule Systems.Scholar.Years do
  @moduledoc """
    Defines scholar years supported by the studentpool app.
  """
  use Core.Enums.Base, {:scholar_years, [:first, :second]}
end
