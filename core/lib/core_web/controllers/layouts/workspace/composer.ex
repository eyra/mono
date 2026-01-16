defmodule CoreWeb.Layouts.Workspace.Composer do
  @moduledoc """
  Workspace layout composer for LiveView pages.

  Supports two modes:
  - Default (Fabric): Uses Fabric.LiveHook for legacy component support
  - LiveNest: Pure LiveNest setup, assumes CoreWeb.routed_live_view is used
  """

  defmacro __using__(opts \\ nil)

  # LiveNest mode: CoreWeb.routed_live_view already mounts User hook
  defmacro __using__(:live_nest) do
    quote do
      unquote(live_nest_setup())
    end
  end

  # Default Fabric mode
  defmacro __using__(_opts) do
    quote do
      on_mount({Frameworks.Fabric.LiveHook, __MODULE__})
      unquote(fabric_setup())
    end
  end

  # LiveNest setup - minimal hooks for LiveNest-based pages
  #
  # Excluded hooks (deprecated with LiveContext):
  # - User: mounted by CoreWeb.routed_live_view, passed via LiveContext
  # - Timezone: deprecated, passed via LiveContext
  #
  # Required hooks:
  # - Base: core functionality
  # - GreenLight: authorization
  # - Viewport: responsive design
  # - RemoteIp: analytics/logging
  # - Locale: needed for routed views, passed via LiveContext to embedded views
  # - Uri: URL handling
  # - Model: ViewBuilder pattern
  # - Project: project context
  # - Observatory: view model updates
  # - Menus: workspace navigation
  # - Tabbed: tab management
  # - Actions: action bar
  defp live_nest_setup do
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
      on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})
      on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Locale, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Project.LiveHook, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Menus, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Tabbed, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Actions, __MODULE__})

      import CoreWeb.Layouts.Workspace.Html

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        {:noreply, socket |> update_menus()}
      end
    end
  end

  # Fabric setup - includes all hooks
  defp fabric_setup do
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
      on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})
      on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Locale, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Project.LiveHook, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Menus, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Tabbed, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Actions, __MODULE__})

      import CoreWeb.Layouts.Workspace.Html

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        {:noreply, socket |> update_menus()}
      end
    end
  end
end
