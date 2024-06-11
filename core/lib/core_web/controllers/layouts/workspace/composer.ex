defmodule CoreWeb.Layouts.Workspace.Composer do
  defmacro __using__(_opts) do
    quote do
      use CoreWeb.LiveMenus, {
        :workspace_menu_builder,
        [
          :mobile_menu,
          :mobile_navbar,
          :desktop_menu,
          :tablet_menu
        ]
      }

      use CoreWeb.UI.PlainDialog

      import CoreWeb.Layouts.Workspace.Composer
      import CoreWeb.Layouts.Workspace.Html

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        {:noreply, socket |> update_menus()}
      end
    end
  end
end
