defmodule MicaWeb.Web do
  @moduledoc """
  The blocks of a web module: controllers, views, components, channels and so on.

  Mica and every SaaS have their own web module, built with this one:

      defmodule NextWeb do
        use MicaWeb.Web, router: MicaWeb.Router, endpoint: NextWeb.Endpoint
      end

  Code then uses its owner's web module, `use NextWeb, :routed_live_view` or
  `use NextWeb, {:controller, formats: [:json]}`, and its `~p` is verified against
  that `router:`. The blocks are the same for every web module; only the paths
  differ. Mica's web module, `use MicaWeb.Web` without a router, builds its paths
  with `~m` (`MicaWeb.Path`), which each SaaS checks against its own router.

  Do NOT define functions inside the quoted expressions below. Instead, define any
  helper function in modules and import those modules here.
  """

  defmacro __using__(opts) do
    quote do
      def verified_routes, do: unquote(paths(opts))

      def utility, do: MicaWeb.Web.utility()
      def controller(opts), do: MicaWeb.Web.controller(opts, verified_routes())
      def ui, do: MicaWeb.Web.ui(verified_routes())
      def pixel, do: MicaWeb.Web.pixel(verified_routes())
      def html, do: MicaWeb.Web.html(verified_routes())
      def live_component, do: MicaWeb.Web.live_component(verified_routes())
      def live_component_fabric, do: MicaWeb.Web.live_component_fabric(verified_routes())
      def live_view_fabric, do: MicaWeb.Web.live_view_fabric(verified_routes())
      def routed_live_view, do: MicaWeb.Web.routed_live_view(verified_routes())
      def embedded_live_view, do: MicaWeb.Web.embedded_live_view(verified_routes())
      def modal_live_view, do: MicaWeb.Web.modal_live_view(verified_routes())
      def live_features, do: MicaWeb.Web.live_features()
      def channel, do: MicaWeb.Web.channel()
      def router, do: MicaWeb.Web.router()

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
  end

  # A SaaS web module (`router:` and `endpoint:`) gets Phoenix's `~p`, verified
  # against its router. Mica's web module, without them, gets `~m` (`MicaWeb.Path`).
  defp paths(opts) do
    case {Keyword.fetch(opts, :router), Keyword.fetch(opts, :endpoint)} do
      {{:ok, router}, {:ok, endpoint}} ->
        quote do: MicaWeb.Web.verified_routes(unquote(router), unquote(endpoint))

      {:error, :error} ->
        quote do: MicaWeb.Web.mica_paths()

      _ ->
        raise ArgumentError, "use MicaWeb.Web takes both :router and :endpoint, or neither"
    end
  end

  def verified_routes(router, endpoint) do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: unquote(endpoint),
        router: unquote(router),
        statics: MicaWeb.Path.statics()
    end
  end

  def mica_paths do
    quote do
      use MicaWeb.Path
    end
  end

  def utility do
    quote do
      use Frameworks.Utility.EnumHelpers
    end
  end

  def controller(opts, routes) do
    quote do
      use Mica, :auth
      use Phoenix.Controller, unquote(opts)

      unquote(utility())

      import Plug.Conn
      use Gettext, backend: MicaWeb.Gettext
      import Mica.FeatureFlags

      alias MicaWeb.Loaders

      import Phoenix.LiveView.Controller

      plug(Systems.Project.BranchPlug)

      unquote(routes)
    end
  end

  def ui(routes) do
    quote do
      use Phoenix.Component

      # Use base HTML functionality
      import Phoenix.HTML, only: [raw: 1]
      import Phoenix.HTML.Form
      import PhoenixHTMLHelpers.Link, only: [link: 2]
      import PhoenixHTMLHelpers.Tag, only: [csrf_meta_tag: 0]
      import PhoenixHTMLHelpers.Form

      use Gettext, backend: MicaWeb.Gettext

      unquote(routes)
      unquote(utility())
    end
  end

  def pixel(routes) do
    quote do
      unquote(ui(routes))
      use MicaWeb.UI
    end
  end

  def html(routes) do
    quote do
      unquote(pixel(routes))
      use Frameworks.Pixel

      unquote(component_helpers())

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]
    end
  end

  def live_component(routes) do
    quote do
      use Phoenix.LiveComponent
      use LiveNest, :live_component

      unquote(pixel(routes))
      use Frameworks.Pixel

      unquote(component_helpers())
    end
  end

  def live_component_fabric(routes) do
    quote do
      use Fabric.LiveComponent
      use LiveNest, :live_component

      unquote(pixel(routes))
      use Frameworks.Pixel

      unquote(component_helpers())
    end
  end

  # DEPRECATED: Use routed_live_view for LiveNest-based views.
  # This version includes Fabric.ModalPresenter which is only needed for Fabric sub-components.
  def live_view_fabric(routes) do
    quote do
      use Phoenix.LiveView, layout: {unquote(MicaWeb.Layouts), :live}
      use LiveNest, :routed_live_view
      use LiveNest, :single_modal_presenter_strategy
      # IMPORTANT: Fabric.LiveView must come before Fabric.ModalPresenter
      # because LiveView defines a catch-all handle_event/3 with defoverridable,
      # and ModalPresenter provides specific handlers for "show_modal", "hide_modal", etc.
      use Fabric.LiveView
      use Fabric.ModalPresenter
      use Frameworks.Pixel.ModalView
      use Frameworks.Signal.LiveFeature
      use Systems.Email.LiveFeature

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Hooks for routed LiveViews (User must come before UserState)
      on_mount({MicaWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.UserState.LiveHook, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Locale, __MODULE__})

      unquote(pixel(routes))
      use Frameworks.Pixel

      unquote(component_helpers())
      unquote(live_features())
    end
  end

  # Routed LiveView for LiveNest-based views with embedded live views.
  # Pure LiveNest setup without Fabric dependencies.
  def routed_live_view(routes) do
    quote do
      use Phoenix.LiveView, layout: {unquote(MicaWeb.Layouts), :live}
      use LiveNest, :routed_live_view
      use LiveNest, :single_modal_presenter_strategy
      use Frameworks.Pixel.ModalView
      use Frameworks.Signal.LiveFeature
      use Systems.Email.LiveFeature

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Hooks for routed LiveViews (User must come before UserState)
      on_mount({MicaWeb.Live.Hook.User, __MODULE__})
      on_mount({Frameworks.UserState.LiveHook, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Locale, __MODULE__})

      unquote(pixel(routes))
      use Frameworks.Pixel

      unquote(component_helpers())
      unquote(live_features())
    end
  end

  def embedded_live_view(routes) do
    quote do
      use Phoenix.LiveView
      use LiveNest, :embedded_live_view
      use Gettext, backend: MicaWeb.Gettext
      use MicaWeb.UI

      # Flash support for embedded views (handles :show_flash and :hide_flash messages)
      use Frameworks.Pixel.Flash
      use Frameworks.Signal.LiveFeature
      use Systems.Email.LiveFeature

      # UserState LiveFeature provides publish_user_state_change
      use Frameworks.UserState.LiveFeature

      # Observatory LiveFeature provides update_view_model and handle_view_model_updated
      use Systems.Observatory.LiveFeature

      require Logger

      # Standard embedded LiveView hooks
      on_mount({MicaWeb.Live.Hook.Base, __MODULE__})
      on_mount({MicaWeb.Live.Hook.User, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Locale, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Timezone, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Context, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Language, __MODULE__})
      on_mount({MicaWeb.Live.Hook.Model, __MODULE__})
      on_mount({Systems.Observatory.LiveHook, __MODULE__})

      # Include stack helpers for block-based architecture
      import MicaWeb.Live.Feature.Stack

      unquote(utility())
      unquote(routes)
    end
  end

  def modal_live_view(routes) do
    quote do
      unquote(embedded_live_view(routes))
      # Modal support: enables publish_event to route to modal controller
      use LiveNest.Modal, :live_view
    end
  end

  def live_features do
    quote do
      use Frameworks.GreenLight.LiveFeature
      use Systems.Observatory.LiveFeature
      use Frameworks.UserState.LiveFeature
      use MicaWeb.Live.Feature.Viewport
      use MicaWeb.Live.Feature.Uri
      use MicaWeb.Live.Feature.Model
      use MicaWeb.Live.Feature.Menus
      use MicaWeb.Live.Feature.Actions
      use MicaWeb.Live.Feature.Stack
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: MicaWeb.Gettext
    end
  end

  defp component_helpers do
    quote do
      use Mica, :auth
      import Mica.FeatureFlags

      use Gettext, backend: MicaWeb.Gettext
      alias MicaWeb.Meta
      alias Frameworks.Utility.ViewModelBuilder

      def version do
        unquote(Mica.Env.fetch!(:version))
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
end
