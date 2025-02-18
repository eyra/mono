defmodule LiveMesh.Fragment do
  @moduledoc """
  A `Fragment` is a reusable LiveComponent that can be included in **any LiveView**.

  ## Key Rules:
  - **By default, Fragments are used inside `Panels`**, but they **can also be included in `Pages` or `Sections`** if needed.
  - **Supports event bubbling** to its parent LiveView.
  - **Cannot contain another LiveComponent**, enforcing a flat UI structure.
  - **Encourages using Functional Components (`HEEx`) inside a Fragment instead of nested LiveComponents**.

  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
    end
  end
end
