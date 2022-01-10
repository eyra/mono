defmodule CoreWeb.UI.Component do
  defmacro __using__(_opts) do
    quote do
      use Surface.Component

      require Frameworks.Pixel.ViewModel
      import Frameworks.Pixel.ViewModel

      import CoreWeb.Gettext

      alias CoreWeb.UI.{Empty, MarginY}
      alias CoreWeb.UI.Container.{ContentArea, FormArea, SheetArea}
      alias Frameworks.Pixel.Case.{Case, True, False}
      alias Frameworks.Pixel.Button.DynamicButton
      alias Frameworks.Pixel.Dynamic
      alias Frameworks.Pixel.{Spacing, Wrap}
    end
  end
end
