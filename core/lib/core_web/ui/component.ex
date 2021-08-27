defmodule CoreWeb.UI.Component do
  defmacro __using__(_opts) do
    quote do
      use Surface.Component

      import CoreWeb.Gettext

      alias CoreWeb.UI.{Empty, MarginY}
      alias CoreWeb.UI.Container.{ContentArea, FormArea, SheetArea}
      alias EyraUI.Case.{Case, True, False}
      alias EyraUI.Button.DynamicButton
      alias EyraUI.Spacing
    end
  end
end
