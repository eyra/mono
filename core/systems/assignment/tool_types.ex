defmodule Systems.Assignment.ToolTypes do
  @moduledoc """
    Defines types of assignment.
  """
  use Core.Enums.Base,
      {:tool_types, [:online, :lab]}
end
