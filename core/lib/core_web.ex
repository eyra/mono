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
    do: ~w(css assets fonts images js favicon logo icon apple-touch-icon robots manifest sw)

  def utility do
    quote do
      use Frameworks.Utility.EnumHelpers
    end
  end

  def controller(
        opts \\ [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]
      ) do
    quote do
      use Phoenix.Controller, unquote(opts)

      unquote(utility())

      import Plug.Conn
      import CoreWeb.Gettext
      import Core.FeatureFlags

      alias CoreWeb.Loaders

      import Phoenix.LiveView.Controller

      plug(Systems.Project.BranchPlug)

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def ui do
    quote do
      use Phoenix.Component

      # Use base HTML functionality
      import Phoenix.HTML, only: [raw: 1]
      import Phoenix.HTML.Form
      import Phoenix.HTML.Link, only: [link: 2]
      import Phoenix.HTML.Tag, only: [csrf_meta_tag: 0]

      import CoreWeb.Gettext

      unquote(verified_routes())
      unquote(utility())
    end
  end

  def pixel do
    quote do
      unquote(ui())
      use CoreWeb.UI
    end
  end

  def html do
    quote do
      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]
    end
  end

  def live_component do
    quote do
      use Fabric.LiveComponent

      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())
    end
  end

  def live_view do
    quote do
      use Fabric.LiveView, CoreWeb.Layouts

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import Core.Authorization, only: [can_access?: 2]

      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())
      unquote(verified_routes())
      unquote(live_features())
    end
  end

  def live_features do
    quote do
      use Frameworks.GreenLight.LiveFeature
      use Systems.Observatory.LiveFeature
      use CoreWeb.Live.Feature.Viewport
      use CoreWeb.Live.Feature.Uri
      use CoreWeb.Live.Feature.Model
      use CoreWeb.Live.Feature.Menus
      use CoreWeb.Live.Feature.Tabbar
      use CoreWeb.Live.Feature.Actions
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

  def auth_helpers() do
    quote do
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
      import Core.FeatureFlags
      import Core.Authorization, only: [can?: 4]

      import CoreWeb.Gettext
      alias CoreWeb.Meta
      alias Frameworks.Utility.ViewModelBuilder

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
