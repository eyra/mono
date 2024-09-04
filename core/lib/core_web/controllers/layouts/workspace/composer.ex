defmodule CoreWeb.Layouts.Workspace.Composer do
  defmacro __using__(_opts) do
    quote do
      def get_menus_config(),
        do: {
          :workspace_menu_builder,
          [
            :mobile_menu,
            :mobile_navbar,
            :desktop_menu,
            :tablet_menu
          ]
        }

      on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
      on_mount({CoreWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
      on_mount({Frameworks.Fabric.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})
      on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Locale, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Project.LiveHook, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Menus, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Tabbar, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Actions, __MODULE__})

      use CoreWeb.UI.PlainDialog

      import CoreWeb.Layouts.Workspace.Html

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        {:noreply, socket |> update_menus()}
      end
    end
  end
end
