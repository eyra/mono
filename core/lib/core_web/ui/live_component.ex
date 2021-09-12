defmodule CoreWeb.UI.LiveComponent do
  defmacro __using__(_opts) do
    quote do
      use Surface.LiveComponent

      import CoreWeb.Gettext

      alias CoreWeb.UI.{Empty, MarginY}
      alias CoreWeb.UI.Container.{ContentArea, FormArea, SheetArea}
      alias EyraUI.Case.{Case, True, False}
      alias EyraUI.Button.DynamicButton
      alias EyraUI.Spacing

      require EyraUI.ViewModel
      import EyraUI.ViewModel

      alias CoreWeb.Router.Helpers, as: Routes
    end
  end
end
