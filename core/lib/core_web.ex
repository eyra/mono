defmodule CoreWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CoreWeb, :controller
      use CoreWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do:
      ~w(css assets fonts images js favicon logo icon apple-touch-icon robots manifest sw privacy-statement.pdf landing_page)

  def controller(
        opts \\ [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]
      ) do
    quote do
      use Phoenix.Controller, unquote(opts)

      import Plug.Conn
      import CoreWeb.Gettext
      import Core.FeatureFlags

      alias CoreWeb.Loaders

      import Phoenix.LiveView.Controller
      alias CoreWeb.Router.Helpers, as: Routes

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      # Include shared imports and aliases for views
      unquote(component_helpers())

      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import Core.FeatureFlags
      alias CoreWeb.Router.Helpers, as: Routes

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CoreWeb.Endpoint,
        router: CoreWeb.Router,
        statics: CoreWeb.static_paths()
    end
  end

  def live_view do
    quote do
      unquote(component_helpers())
      use Phoenix.LiveView, layout: {CoreWeb.Layouts, :live}

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      use CoreWeb.LiveLocale
      use CoreWeb.LiveUri
      import Core.Authorization, only: [can_access?: 2]
      use Frameworks.GreenLight.Live, Core.Authorization
      alias CoreWeb.Router.Helpers, as: Routes

      use CoreWeb.LiveAssignHelper
      import Core.FeatureFlags

      use Frameworks.Pixel.Flash

      import CoreWeb.UrlResolver, only: [url_resolver: 1]

      import CoreWeb.UI.Popup
      import CoreWeb.UI.Empty
      alias CoreWeb.UI.Margin

      alias CoreWeb.UI.Area

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def live_component do
    quote do
      unquote(component_helpers())

      use Phoenix.LiveComponent

      def update_target(%{type: type, id: id}, message) when is_map(message) do
        send_update(type, message |> Map.put(:id, id))
      end

      def update_target(pid, message) when is_pid(pid) do
        send(pid, message)
      end

      def update_defaults(%{assigns: assigns} = socket, props, defaults) do
        assigns =
          Enum.reduce(defaults, assigns, fn {key, default}, acc ->
            value = Map.get(props, key, default)
            Map.put(acc, key, value)
          end)

        Map.put(socket, :assigns, assigns)
      end

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import CoreWeb.Gettext
    end
  end

  defp component_helpers do
    quote do
      # Use base HTML functionality
      import Phoenix.HTML, only: [raw: 1]
      import Phoenix.HTML.Form
      import Phoenix.HTML.Link, only: [link: 2]
      import Phoenix.HTML.Tag, only: [csrf_meta_tag: 0]

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic component functionality
      import Phoenix.Component

      import Frameworks.Pixel.ErrorHelpers
      import CoreWeb.Gettext
      import CoreWeb.UI.FunctionComponent

      import Frameworks.Pixel.Spacing
      import Frameworks.Pixel.Wrap
      alias Frameworks.Pixel.Button
      alias Frameworks.Pixel.Text
      alias Frameworks.Pixel.Icon
      alias CoreWeb.UI.Margin
      alias CoreWeb.UI.Area

      import Core.Authorization, only: [can?: 4]
      alias CoreWeb.Meta
      alias Frameworks.Utility.ViewModelBuilder

      def current_user(%{assigns: %{current_user: current_user}}), do: current_user
      def current_user(_conn), do: nil

      def version do
        unquote(Application.fetch_env!(:core, :version))
      end
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
