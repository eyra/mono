defmodule Frameworks.Pixel.Component do
  defmacro __using__(_props \\ []) do
    quote do
      use Surface.Component

      require Frameworks.Pixel.ViewModel
      import Frameworks.Pixel.ViewModel
    end
  end
end
