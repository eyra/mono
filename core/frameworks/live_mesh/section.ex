defmodule LiveMesh.Section do
  @moduledoc """
    A `Section` is the primary organizational unit in LiveMesh.

    - Supports nesting other `Sections` and `Panels` by default.
    - Does **not** support `Fragments` unless explicitly enabled via `use LiveMesh.Fragments`.
    - Does **not** support `Modals` unless explicitly enabled via `use LiveMesh.Modals`.
    - Handles event bubbling from `Panels` and `Fragments`.
  """

  use Phoenix.LiveView

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      use LiveMesh.Sections
      use LiveMesh.Panels
      use LiveMesh.Events
    end
  end
end
