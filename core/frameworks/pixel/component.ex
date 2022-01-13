defmodule Frameworks.Pixel.Component do
  defmacro __using__(_props \\ []) do
    quote do
      use Surface.Component

      alias Surface.Components.Dynamic

      require Frameworks.Pixel.ViewModel
      import Frameworks.Pixel.ViewModel
    end
  end
end
