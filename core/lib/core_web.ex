defmodule CoreWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CoreWeb, {:controller, [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}
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

  def controller(opts) do
    quote do
      use Core, :auth
      use Phoenix.Controller, unquote(opts)

      unquote(utility())

      import Plug.Conn
      use Gettext, backend: CoreWeb.Gettext
      import Core.FeatureFlags

      alias CoreWeb.Loaders

      import Phoenix.LiveView.Controller

      plug(Systems.Project.BranchPlug)

      unquote(verified_routes())
    end
  end

  def ui do
    quote do
      use Phoenix.Component

      # Use base HTML functionality
      import Phoenix.HTML, only: [raw: 1]
      import Phoenix.HTML.Form
      import PhoenixHTMLHelpers.Link, only: [link: 2]
      import PhoenixHTMLHelpers.Tag, only: [csrf_meta_tag: 0]
      import PhoenixHTMLHelpers.Form

      use Gettext, backend: CoreWeb.Gettext

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
      use LiveNest, :live_component

      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())
    end
  end

  # DEPRECATED: Use routed_live_view for LiveNest-based views.
  # This version includes Fabric.ModalPresenter which is only needed for Fabric sub-components.
  def live_view do
    quote do
      use Phoenix.LiveView, layout: {unquote(CoreWeb.Layouts), :live}
      use LiveNest, :routed_live_view
      use LiveNest, :single_modal_presenter_strategy
      # IMPORTANT: Fabric.LiveView must come before Fabric.ModalPresenter
      # because LiveView defines a catch-all handle_event/3 with defoverridable,
      # and ModalPresenter provides specific handlers for "show_modal", "hide_modal", etc.
      use Fabric.LiveView
      use Fabric.ModalPresenter
      use Frameworks.Pixel.ModalView

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Hooks for routed LiveViews (User must come before UserState)
      on_mount({CoreWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.UserState.LiveHook, __MODULE__})

      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())
      unquote(verified_routes())
      unquote(live_features())
    end
  end

  # Routed LiveView for LiveNest-based views with embedded live views.
  # Pure LiveNest setup without Fabric dependencies.
  def routed_live_view do
    quote do
      use Phoenix.LiveView, layout: {unquote(CoreWeb.Layouts), :live}
      use LiveNest, :routed_live_view
      use LiveNest, :single_modal_presenter_strategy
      use Frameworks.Pixel.ModalView

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Hooks for routed LiveViews (User must come before UserState)
      on_mount({CoreWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.UserState.LiveHook, __MODULE__})

      unquote(pixel())
      use Frameworks.Pixel

      unquote(component_helpers())
      unquote(verified_routes())
      unquote(live_features())
    end
  end

  def embedded_live_view do
    quote do
      use Phoenix.LiveView
      use LiveNest, :embedded_live_view
      use Gettext, backend: CoreWeb.Gettext
      use CoreWeb.UI

      # Flash support for embedded views (handles :show_flash and :hide_flash messages)
      use Frameworks.Pixel.Flash

      # UserState LiveFeature provides publish_user_state_change
      use Frameworks.UserState.LiveFeature

      # Observatory LiveFeature provides update_view_model and handle_view_model_updated
      use Systems.Observatory.LiveFeature

      require Logger

      # Standard embedded LiveView hooks
      on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
      on_mount({CoreWeb.Live.Hook.User, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Context, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Language, __MODULE__})
      on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})

      # Include stack helpers for block-based architecture
      import CoreWeb.Live.Feature.Stack

      unquote(utility())
      unquote(verified_routes())
    end
  end

  def modal_live_view do
    quote do
      unquote(embedded_live_view())
      # Modal support: enables publish_event to route to modal controller
      use LiveNest.Modal, :live_view
    end
  end

  def live_features do
    quote do
      use Frameworks.GreenLight.LiveFeature
      use Systems.Observatory.LiveFeature
      use Frameworks.UserState.LiveFeature
      use CoreWeb.Live.Feature.Viewport
      use CoreWeb.Live.Feature.Uri
      use CoreWeb.Live.Feature.Model
      use CoreWeb.Live.Feature.Menus
      use CoreWeb.Live.Feature.Tabbed
      use CoreWeb.Live.Feature.Actions
      use CoreWeb.Live.Feature.Stack
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

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: CoreWeb.Gettext
    end
  end

  defp component_helpers do
    quote do
      use Core, :auth
      import Core.FeatureFlags

      use Gettext, backend: CoreWeb.Gettext
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
