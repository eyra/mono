defmodule Core.System do
  @moduledoc """
  The contract of one system: what it contributes to the SaaS it is part of.

  Every system that contributes something has one `_system.ex`, next to its
  `_routes.ex` and `_switch.ex`, defining `Systems.X.System` (or `Next.X.System`,
  `Self.X.System` for a SaaS's own systems). A SaaS lists its systems in
  `c:Core.SaaS.systems/0`; `Core.SaaS` collects their contributions.

      defmodule Systems.Pool.System do
        use Core.System

        def routes do
          quote do
            require Systems.Pool.Routes
            Systems.Pool.Routes.routes()
          end
        end

        def grants do
          quote do
            [
              {Systems.Pool.LandingPage, [:visitor, :member, :owner]},
              {Systems.Pool.ContentPage, [:admin]}
            ]
          end
        end
      end

  System modules are data modules and never call system code. The router and
  `Core.Authorization` read `override_routes/0`, `routes/0` and `grants/0` at
  compile time, so these return quoted code. `grants/0` is quoted too: a module
  name used as a value is a runtime dependency, and that would make the router
  recompile whenever any granted page changes. The other callbacks return plain
  values, which `Core.SaaS` collects (`notify_channels/0` also at compile time,
  for the `Systems.Notify.MessageModel` enum).

  A SaaS extends Mica's systems only through its own systems, for example by
  shadowing Mica's sign-in routes with `override_routes/0`.

  Callbacks are only ever added with a default; removing or changing one breaks
  the contract with every SaaS.
  """

  @doc """
  Routes that must match before every other route, such as a SaaS's own sign-in
  pages. Spliced at the top of `CoreWeb.Router`, in `c:Core.SaaS.systems/0` order.
  """
  @callback override_routes() :: Macro.t() | nil

  @doc "The system's routes, spliced inside `CoreWeb.Routes` in `c:Core.SaaS.systems/0` order."
  @callback routes() :: Macro.t() | nil

  @doc """
  Quoted list of page grants: `{module, roles}` for `grant_access/2`, or
  `{module, %{action => roles}}` for `grant_actions/2`.
  """
  @callback grants() :: Macro.t()

  @doc """
  The system's `Frameworks.Signal.Handler` modules (its `_switch.ex`).
  `c:Core.SaaS.signal_handlers/0` dispatches to all of them, sorted by module name.
  """
  @callback signal_handlers() :: [module()]

  @doc "The system's `Systems.Notify.EventDeclaration` modules (its `_notify.ex`)."
  @callback notifiers() :: [module()]

  @doc "The notification channels the system delivers: name to `Systems.Notify.Channel` module."
  @callback notify_channels() :: %{atom() => module()}

  @doc """
  The system's `Systems.Admin.Panel` modules: tabs on the Admin page, shown
  after the panels of earlier systems in `c:Core.SaaS.systems/0`.
  """
  @callback admin_panels() :: [module()]

  @doc """
  The system's `Systems.Account.Tab` modules: tabs on the account page, shown
  after the tabs of earlier systems in `c:Core.SaaS.systems/0`.
  """
  @callback account_tabs() :: [module()]

  @doc """
  The system's `Systems.Desktop.Section` modules: sections on the Desktop page,
  shown after Recent items and the sections of earlier systems in
  `c:Core.SaaS.systems/0`.
  """
  @callback desktop_sections() :: [module()]

  @doc """
  The system's `Systems.Account.SignInHandoff` modules. When an
  identity-provider sign-in ends, the first one that takes it answers instead
  of the site, in `c:Core.SaaS.systems/0` order.
  """
  @callback sign_in_handoffs() :: [module()]

  @doc """
  Processes the system needs, started under `Core.Supervisor` after
  `Phoenix.PubSub` and before Oban, in `c:Core.SaaS.systems/0` order.
  """
  @callback children() :: [Supervisor.child_spec() | {module(), term()} | module()]

  @doc "The Oban queues the system's workers use, with their limits: `[email_delivery: 1]`."
  @callback oban_queues() :: keyword(pos_integer())

  @doc """
  The system's Oban cron jobs, by the name `ENABLED_OBAN_PLUGINS` enables them
  with: `[advert_expiration: {"*/5 * * * *", Systems.Advert.ExpirationWorker}]`.
  An entry is an `Oban.Plugins.Cron` crontab entry. A cron runs only where its
  name is enabled (`Core.ObanConfig`).
  """
  @callback oban_crons() :: keyword({String.t(), module()} | {String.t(), module(), keyword()})

  @doc """
  The default `Systems.Rate` quotas of the services the system limits, as keyword
  lists: `[service: :signup, limit: 5, unit: :call, window: :minute, scope: :local]`.
  """
  @callback rate_quotas() :: [keyword()]

  @doc """
  The feature flags the system reads, as names. A declared flag is off unless
  `c:Core.SaaS.feature_flags/0` or the app config turns it on. Several systems
  may declare the same flag.
  """
  @callback feature_flags() :: [atom()]

  @doc """
  Seeds the records the system needs in the deploy environment (`:prod`,
  `:staging`, `:dev`, `:test`, `:local`). `Core.Seeds` runs it on every
  deployment, after Mica's own seeds and in `c:Core.SaaS.systems/0` order, so
  it must be idempotent.
  """
  @callback seeds(deploy_env :: atom()) :: :ok

  @doc """
  The absolute path of the system's own Ecto migrations, or `nil` when its
  tables are in Mica's migrations. Migrated with Mica's, see
  `Core.SaaS.migrations_paths/0`.
  """
  @callback migrations_path() :: Path.t() | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.System

      def override_routes, do: nil
      def routes, do: nil
      def grants, do: quote(do: [])
      def signal_handlers, do: []
      def notifiers, do: []
      def notify_channels, do: %{}
      def admin_panels, do: []
      def account_tabs, do: []
      def desktop_sections, do: []
      def sign_in_handoffs, do: []
      def children, do: []
      def oban_queues, do: []
      def oban_crons, do: []
      def rate_quotas, do: []
      def feature_flags, do: []
      def seeds(_deploy_env), do: :ok
      def migrations_path, do: nil

      defoverridable Core.System
    end
  end
end
