defmodule MicaWeb.Layouts.Website.Composer do
  defmacro __using__(_) do
    quote do
      def get_menus_config(),
        do: {
          :website_menu_builder,
          [
            :mobile_menu,
            :mobile_navbar,
            :desktop_navbar
          ]
        }

      on_mount({MicaWeb.Live.Hook.Base, __MODULE__})
      on_mount({MicaWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
      on_mount({Frameworks.Fabric.LiveHook, __MODULE__})
      on_mount({MicaWeb.Live.Hook.RemoteIp, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Locale, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Uri, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Project.LiveHook, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Menus, __MODULE__})

      import MicaWeb.Layouts.Website.Html

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        {:noreply, socket |> update_menus()}
      end
    end
  end
end
