defmodule Frameworks.Pixel do
  defmacro __using__(_) do
    quote do
      use Frameworks.Pixel.Flash
      import Frameworks.Pixel.ErrorHelpers
      import CoreWeb.UI.Wrap
      alias Frameworks.Pixel.Align
      alias Frameworks.Pixel.Button
      alias Frameworks.Pixel.Text
      alias Frameworks.Pixel.Icon
    end
  end
end
