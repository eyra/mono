defmodule Frameworks.Pixel do
  @moduledoc """
  Mica's UI framework. `use Frameworks.Pixel` brings Pixel's helpers and aliases
  into a view.

  Prism's components are function components of this module (`Pixel.button/1`,
  `Pixel.tag/1`, …), built from Prism's design while Mica compiles. See
  `Prism.Generator.Phoenix`.
  """
  use Prism.Generator.Phoenix, design: Prism.Design.Components

  defmacro __using__(_) do
    quote do
      use Frameworks.Pixel.Flash
      import Frameworks.Pixel.ErrorHelpers
      import MicaWeb.UI.Wrap
      alias Frameworks.Pixel.Align
      alias Frameworks.Pixel.Button
      alias Frameworks.Pixel.Text
      alias Frameworks.Pixel.Icon
      alias Frameworks.Pixel.Separator
    end
  end
end
