defmodule LiveMesh.Panel do
  @moduledoc """
  A `Panel` is a structured container for Fragments.

  ## Key Rules:
  - **By default, Panels are used inside `Sections`**, but they **can also be included in Pages** if `use LiveMesh.Panels` is enabled.
  - **Can only contain Fragments (`LiveMesh.Fragment`)**.
  - **Supports event bubbling** to its parent Section or Page.
  """

  use Phoenix.LiveView

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      use LiveMesh.Panels
      use LiveMesh.Events
    end
  end
end
