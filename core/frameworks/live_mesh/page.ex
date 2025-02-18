defmodule LiveMesh.Page do
  @moduledoc """
  The base module for LiveMesh pages.

  A `Page` serves as the root LiveView for a structured UI. By default, it:
  - Supports `Sections` as the main building blocks.
  - Manages `Modals` natively.
  - Does **not** support `Panels` and `Fragments` unless explicitly enabled.
  - Handles event bubbling from `Sections` and `Panels`.
  """

  use Phoenix.LiveView

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      use LiveMesh.Sections
      use LiveMesh.Modals
    end
  end
end
