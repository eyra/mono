defmodule CoreWeb.Layouts.Stripped.Composer do
  def stripped_menus_config(),
    do: {
      :stripped_menu_builder,
      [
        :mobile_navbar,
        :desktop_navbar
      ],
      nil
    }

  defmacro __using__(_) do
    quote do
      def get_menus_config(), do: CoreWeb.Layouts.Stripped.Composer.stripped_menus_config()

      on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
      on_mount({CoreWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
      on_mount({Frameworks.Fabric.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Locale, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Project.LiveHook, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Menus, __MODULE__})

      use CoreWeb.UI.PlainDialog

      import CoreWeb.Layouts.Stripped.Html
      import Systems.Content.Html, only: [live_stripped: 1]
    end
  end
end
