defmodule CoreWeb.UI.LiveComponent do
  defmacro __using__(_opts) do
    quote do
      use Surface.LiveComponent

      import CoreWeb.Gettext

      alias Surface.Components.Dynamic
      alias CoreWeb.UI.{Empty, MarginY}
      alias CoreWeb.UI.Container.{ContentArea, FormArea, SheetArea}
      alias Frameworks.Pixel.Case.{Case, True, False}
      alias Frameworks.Pixel.Button.DynamicButton
      alias Frameworks.Pixel.Spacing
      alias Frameworks.Pixel.Wrap
      alias CoreWeb.Router.Helpers, as: Routes

      require Frameworks.Pixel.ViewModel
      import Frameworks.Pixel.ViewModel

      def update_target(%{type: type, id: id}, message) when is_map(message) do
        send_update(type, message |> Map.put(:id, id))
      end

      def update_target(pid, message) when is_pid(pid) do
        send(pid, message)
      end
    end
  end
end
