defmodule LinkWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LinkWeb, :controller
      use LinkWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LinkWeb

      import Plug.Conn
      import LinkWeb.Gettext
      alias LinkWeb.Router.Helpers, as: Routes

      alias LinkWeb.Loaders

      import Phoenix.LiveView.Controller
    end
  end

  def view(opts \\ [root: "lib/link_web/templates", namespace: LinkWeb]) do
    quote do
      use Phoenix.View, unquote(opts)

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())

      # use Link.Authorization.Controller, :view
    end
  end

  def live_view do
    quote do
      use LinkWeb.LiveLocale
      import Link.Authorization, only: [can_access?: 2]
      use GreenLight.Live, Link.Authorization

      use Surface.LiveView,
        layout: {LinkWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import LinkWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import LinkWeb.ErrorHelpers
      import LinkWeb.Gettext
      import LinkWeb.Components.OldSkool
      alias LinkWeb.Router.Helpers, as: Routes
      import Link.Authorization, only: [can?: 4]
      use LinkWeb.LiveViewPowHelper

      def supported_languages do
        current_locale = Gettext.get_locale()

        [
          {"en", gettext("English")},
          {"nl", gettext("Dutch")}
        ]
        |> Enum.reject(fn {locale, _} -> current_locale == locale end)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc applying given opts.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end
end
