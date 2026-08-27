defmodule Frameworks.Pixel do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Frameworks.Pixel.Flash

      import CoreWeb.UI.Wrap
      import Frameworks.Pixel.ErrorHelpers

      alias Frameworks.Pixel.Align
      alias Frameworks.Pixel.Button
      alias Frameworks.Pixel.Icon
      alias Frameworks.Pixel.Separator
      alias Frameworks.Pixel.Text
    end
  end
end
