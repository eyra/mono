defmodule CoreWeb.UI.LiveComponent do
  defmacro __using__(_opts) do
    quote do
      use Surface.LiveComponent

      import CoreWeb.Gettext

      alias CoreWeb.UI.{Empty, MarginY}
      alias CoreWeb.UI.Container.{ContentArea, FormArea, SheetArea}
      alias Frameworks.Pixel.Case.{Case, True, False}
      alias Frameworks.Pixel.Button.DynamicButton
      alias Frameworks.Pixel.Spacing

      require Frameworks.Pixel.ViewModel
      import Frameworks.Pixel.ViewModel

      alias CoreWeb.Router.Helpers, as: Routes
    end
  end
end
