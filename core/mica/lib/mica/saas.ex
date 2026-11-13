defmodule Mica.SaaS do
  @moduledoc """
  A SaaS built on Mica, and the composition of the configured one.

  Each SaaS has one module that implements this behaviour (`Next.SaaS`,
  `MicaSaas.SaaS`). It lists the systems the SaaS is made of and carries the
  SaaS-level config. The build picks one in its config:

      config :mica, saas: Next.SaaS

  Mica reads the value at runtime. At boot `validate!/0` builds the
  composition, the contributions of all systems, checks it and caches it; the
  readers below (`signal_handlers/0`, `grants/0`, ...) take their part from
  that cache. Only `MicaWeb.Router` still reads the value at compile time, to
  splice the routes of all systems (`override_routes/0`, `routes/0`). Never set
  `:saas` in `runtime.exs`; a release refuses to boot when it differs from the
  value the router was compiled with.
  """

  @doc "The systems the SaaS is made of: `Mica.Systems.all() ++` its own systems."
  @callback systems() :: [module()]

  @doc "The `MicaWeb.StartPageProvider` implementation."
  @callback start_pages() :: module()

  @doc "The `MicaWeb.Menu.ItemsProvider` implementation."
  @callback menu_items() :: module()

  @doc "The menu builder for a layout."
  @callback menu_builder(:workspace | :website | :stripped) :: module()

  @doc "The product name shown in page titles."
  @callback title() :: String.t()

  @doc "Where a user lands after signing in, unless a return path is set."
  @callback signed_in_page(:creator | :member) :: String.t()

  @doc "Where a signed-out user is sent to sign in."
  @callback sign_in_page() :: String.t()

  @doc "Where a signed-out user is sent to sign in for a page participants open, which they return to."
  @callback member_sign_in_page(return_to :: String.t()) :: String.t()

  @doc """
  Where a signed-out user is sent to sign up instead of the password sign-up
  page (`/user/signup/:user_type`), or nil to keep that page. The page's
  `post_signup_action` param is passed along, nil when it has none.
  """
  @callback sign_up_page(
              user_type :: :creator | :participant,
              post_signup_action :: String.t() | nil
            ) :: String.t() | nil

  @doc """
  The SaaS defaults of declared feature flags: `[password_sign_in: true]`. Every
  name must be declared by one of its systems (`c:Mica.System.feature_flags/0`).
  """
  @callback feature_flags() :: keyword(boolean())

  @optional_callbacks title: 0,
                      sign_in_page: 0,
                      member_sign_in_page: 1,
                      sign_up_page: 2,
                      feature_flags: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour Mica.SaaS

      def title, do: "Mica"
      def feature_flags, do: []

      def sign_in_page, do: "/user/signin"

      def member_sign_in_page(_return_to), do: sign_in_page()

      def sign_up_page(_user_type, _post_signup_action), do: nil

      defoverridable title: 0,
                     sign_in_page: 0,
                     member_sign_in_page: 1,
                     sign_up_page: 2,
                     feature_flags: 0
    end
  end

  require Logger

  @key {__MODULE__, :composition}

  # Mica.Systems, by path: naming it here would make it a dependency of the callers.
  @core_systems_source Path.expand("systems.ex", __DIR__)

  @doc "The configured SaaS module (`config :mica, saas:`)."
  def module do
    Mica.Env.get(:saas) ||
      raise "config :mica, saas: is not set; the SaaS config (next/config/config.exs, " <>
              "mica_saas/config/config.exs) names the SaaS module"
  end

  @doc """
  Builds the composition of the configured SaaS, checks it (`validate!/1`) and
  caches it. `Mica.Application` runs it at boot, before the children start, so
  a broken composition stops the boot.
  """
  def validate! do
    saas = module()
    composition = validate!(saas)
    :persistent_term.put(@key, composition)
    Logger.info("#{inspect(saas)}: #{length(composition.systems)} systems, composition valid")
    :ok
  end

  @doc """
  The composition of `saas`, after checking it. Raises on:

    * a SaaS module that is no `Mica.SaaS`, or a system that is no `Mica.System`
    * a system, signal handler, notifier, sign-in handoff or assignment template
      listed twice, or an event type that two notifiers declare
    * a notify channel, Oban queue, Oban cron, Desktop section id or BFF page
      that two systems declare
    * a flag default that no system declares
    * a permission granted twice, unless the later grant says `widen: true`;
      each widening is logged
    * a notifier event routed to a channel that no system declares
  """
  def validate!(saas) do
    composition = build(saas)
    collect_oban_queues(composition.systems)
    collect_oban_crons(composition.systems)

    unique!(composition.signal_handlers, "signal handler")
    unique!(composition.notifiers, "notifier")
    unique!(Enum.map(notify_events(composition.notifiers), &elem(&1, 0)), "notify event type")
    unique!(composition.sign_in_handoffs, "sign-in handoff")
    unique!(Enum.map(composition.assignment_templates, & &1.id()), "assignment template id")
    check_event_channels!(composition)
    check_grants!(saas, composition.grants)

    composition
  end

  # The composition the readers below take their parts from: built on first use,
  # or by `validate!/0` at boot, and cached until the node restarts. A dev server
  # picks up a changed contribution on restart.
  defp composition do
    case :persistent_term.get(@key, nil) do
      nil ->
        composition = validate!(module())
        :persistent_term.put(@key, composition)
        composition

      composition ->
        composition
    end
  end

  defp fetch(part), do: Map.fetch!(composition(), part)

  @doc """
  Test hook: replaces parts of the composition for every process. Returns the
  composition it replaced, to put back when the test ends:

      previous = Mica.SaaS.put_composition(signal_handlers: [MyTest.Switch])
      on_exit(fn -> Mica.SaaS.put_composition(previous) end)

  The result is not checked, so a test can put a broken composition. A test
  that calls it must not be `async`.
  """
  def put_composition(parts) do
    previous = composition()
    parts = Map.new(parts)

    case Map.keys(parts) -- Map.keys(previous) do
      [] -> :persistent_term.put(@key, previous |> Map.merge(parts) |> derive())
      unknown -> raise ArgumentError, "not a part of the composition: #{inspect(unknown)}"
    end

    previous
  end

  @doc false
  def build(saas) do
    systems = checked_systems(saas)

    derive(%{
      systems: systems,
      signal_handlers: collect_signal_handlers(systems),
      notifiers: Enum.flat_map(systems, & &1.notifiers()),
      notify_channels: collect_notify_channels(systems),
      admin_panels: Enum.flat_map(systems, & &1.admin_panels()),
      account_tabs: Enum.flat_map(systems, & &1.account_tabs()),
      desktop_sections: collect_desktop_sections(systems),
      sign_in_handoffs: Enum.flat_map(systems, & &1.sign_in_handoffs()),
      bff_pages: collect_bff_pages(systems),
      assignment_templates: Enum.flat_map(systems, & &1.assignment_templates()),
      feature_flags: collect_feature_flags(saas, systems),
      grants: collect_grants(systems),
      schemas: saas |> composition_apps(systems) |> collect_schemas()
    })
  end

  # Parts computed from other parts, so that `put_composition/1` keeps them in step.
  defp derive(composition),
    do: Map.put(composition, :notify_events, Map.new(notify_events(composition.notifiers)))

  defp notify_events(notifiers) do
    for notifier <- notifiers,
        {type, opts} <- notifier.notify_events(),
        do: {to_string(type), Keyword.get(opts, :channels, [])}
  end

  defp unique!(list, what) do
    case list -- Enum.uniq(list) do
      [] ->
        :ok

      duplicates ->
        raise ArgumentError,
              "#{what} #{inspect(Enum.uniq(duplicates))} is listed more than once"
    end
  end

  defp check_event_channels!(%{notify_events: events, notify_channels: channels}) do
    for {type, event_channels} <- events,
        channel <- event_channels,
        not Map.has_key?(channels, channel) do
      raise ArgumentError,
            "notify event #{inspect(type)} is routed to channel #{inspect(channel)}, " <>
              "which no system declares"
    end

    :ok
  end

  # The merge `Mica.Authorization.permission_map/0` makes of its own grants and these.
  defp check_grants!(saas, grants) do
    Frameworks.GreenLight.Permissions.grants_permission_map(
      Mica.Authorization.compiled_permission_map(),
      grants
    )

    for {module, roles, widen: true} <- grants do
      Logger.info(
        "#{inspect(saas)}: the grant of #{inspect(module)} to #{inspect(roles)} widens another grant"
      )
    end

    :ok
  end

  @doc "The systems the SaaS is made of, in `c:systems/0` order."
  def systems, do: fetch(:systems)

  @doc """
  The signal handlers of all systems, sorted by module name within the system
  namespaces: a SaaS system's handler (`Next.Systems.<System>.Switch`) sorts as
  `Systems.<System>.Switch`, among Mica's.
  """
  def signal_handlers, do: fetch(:signal_handlers)

  @doc false
  def collect_signal_handlers(systems),
    do: systems |> Enum.flat_map(& &1.signal_handlers()) |> Enum.sort_by(&handler_order/1)

  defp handler_order(handler) do
    case Module.split(handler) do
      [_saas, "Systems" | rest] -> {Enum.join(["Systems" | rest], "."), inspect(handler)}
      _ -> {inspect(handler), inspect(handler)}
    end
  end

  @doc "The notifiers of all systems, in `systems/0` order."
  def notifiers, do: fetch(:notifiers)

  @doc "The notify event types of all notifiers, to the channels each is routed to: `%{\"type\" => [:email]}`."
  def notify_events, do: fetch(:notify_events)

  @doc "The notification channels of all systems."
  def notify_channels, do: fetch(:notify_channels)

  @doc "The admin panels of all systems, in `systems/0` order."
  def admin_panels, do: fetch(:admin_panels)

  @doc "The account tabs of all systems, in `systems/0` order."
  def account_tabs, do: fetch(:account_tabs)

  @doc "The Desktop sections of all systems, in `systems/0` order."
  def desktop_sections, do: fetch(:desktop_sections)

  @doc "The sign-in handoffs of all systems, in `systems/0` order."
  def sign_in_handoffs, do: fetch(:sign_in_handoffs)

  @doc "The BFF pages of all systems."
  def bff_pages, do: fetch(:bff_pages)

  @doc "The assignment templates of all systems, in `systems/0` order."
  def assignment_templates, do: fetch(:assignment_templates)

  @doc "The children of all systems, in `systems/0` order. Read once, at boot."
  def children, do: collect_children(systems())

  @doc "The Oban queues of all systems. Read once, at boot."
  def oban_queues, do: collect_oban_queues(systems())

  @doc "The Oban crons of all systems, in `systems/0` order. Read once, at boot."
  def oban_crons, do: collect_oban_crons(systems())

  @doc "The default rate quotas of all systems, in `systems/0` order. Read once, at boot."
  def rate_quotas, do: Enum.flat_map(systems(), & &1.rate_quotas())

  @doc """
  The Ecto migration paths to run: Mica's own, then those of the systems that
  have their own, in `systems/0` order.
  """
  def migrations_paths do
    [
      Application.app_dir(Mica.Env.app(), "priv/repo/migrations")
      | collect_migrations_paths(systems())
    ]
  end

  @doc """
  The Ecto schemas of every application in the composition: Mica's and those of
  the applications that hold the SaaS module or one of its systems.
  `Mica.Repo.orphan?/2` and `Mica.Authorization` scan them.

  The list comes from the applications, not from a callback per system, so a
  system can't leave one of its schemas out. A schema in an application that
  holds neither the SaaS module nor any of its systems is not in it.
  """
  def schemas, do: fetch(:schemas)

  @doc false
  def composition_apps(saas, systems) do
    [Mica.Env.app() | Enum.map([saas | systems], &Application.get_application/1)]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc false
  def collect_schemas(apps) do
    for app <- apps,
        module <- Application.spec(app, :modules) || [],
        Code.ensure_loaded?(module) and function_exported?(module, :__schema__, 1),
        do: module
  end

  @doc false
  def collect_migrations_paths(systems),
    do: Enum.flat_map(systems, &List.wrap(&1.migrations_path()))

  @doc """
  The declared feature flags of all systems, off unless the SaaS turns them on,
  sorted by name.
  """
  def feature_flags, do: fetch(:feature_flags)

  @doc false
  def collect_feature_flags(saas, systems) do
    declared = systems |> Enum.flat_map(& &1.feature_flags()) |> Enum.uniq()
    defaults = saas.feature_flags()

    case Keyword.keys(defaults) -- declared do
      [] ->
        declared |> Enum.map(&{&1, false}) |> Keyword.merge(defaults) |> Enum.sort()

      undeclared ->
        raise ArgumentError,
              "#{inspect(saas)}.feature_flags/0 sets #{inspect(undeclared)}, " <>
                "which none of its systems declares"
    end
  end

  @doc false
  def collect_children(systems), do: Enum.flat_map(systems, & &1.children())

  @doc false
  def collect_desktop_sections(systems) do
    for system <- systems, section <- system.desktop_sections(), reduce: [] do
      sections ->
        if Enum.any?(sections, &(&1.id() == section.id())) do
          raise ArgumentError,
                "Desktop section id #{inspect(section.id())} is declared by more than one section"
        end

        sections ++ [section]
    end
  end

  @doc false
  def collect_bff_pages(systems) do
    for system <- systems, {name, module} <- system.bff_pages(), reduce: %{} do
      pages ->
        if Map.has_key?(pages, name) do
          raise ArgumentError, "BFF page #{inspect(name)} is served by more than one system"
        end

        Map.put(pages, name, module)
    end
  end

  @doc false
  def collect_oban_queues(systems) do
    for system <- systems, {name, _limit} = queue <- system.oban_queues(), reduce: [] do
      queues ->
        if Keyword.has_key?(queues, name) do
          raise ArgumentError, "Oban queue #{inspect(name)} is declared by more than one system"
        end

        queues ++ [queue]
    end
  end

  @doc false
  def collect_oban_crons(systems) do
    for system <- systems, {name, _entry} = cron <- system.oban_crons(), reduce: [] do
      crons ->
        if Keyword.has_key?(crons, name) do
          raise ArgumentError, "Oban cron #{inspect(name)} is declared by more than one system"
        end

        crons ++ [cron]
    end
  end

  @doc false
  def collect_notify_channels(systems) do
    for system <- systems, {name, channel} <- system.notify_channels(), reduce: %{} do
      channels ->
        if Map.has_key?(channels, name) do
          raise ArgumentError,
                "notify channel #{inspect(name)} is declared by more than one system"
        end

        Map.put(channels, name, channel)
    end
  end

  @doc """
  Splices `override_routes/0` of all systems, and records their paths for
  `MicaWeb.PathCheck` (a SaaS's own pages that shadow Mica's).
  """
  defmacro override_routes do
    block = splice(:override_routes)

    quote do
      require MicaWeb.PathCheck
      MicaWeb.PathCheck.overrides(do: unquote(block))
    end
  end

  @doc "Splices `routes/0` of all systems, in `systems/0` order."
  defmacro routes, do: splice(:routes)

  @doc """
  The page grants of all systems, in `systems/0` order: `{module, roles}` or
  `{module, %{action => roles}}`, with `widen: true` as a third element when
  the grant widens another one. `Mica.Authorization` merges them into its
  permission map at boot.
  """
  def grants, do: fetch(:grants)

  @doc false
  def collect_grants(systems), do: Enum.flat_map(systems, &system_grants/1)

  defp splice(callback) do
    systems = checked_systems(module())
    body = for system <- systems, code = call(system, callback), code != nil, do: code
    {:__block__, [], external_resources(systems) ++ body}
  end

  defp system_grants(system) do
    case system.grants() do
      grants when is_list(grants) ->
        Enum.map(grants, fn
          {module, roles} = grant when is_atom(module) and (is_list(roles) or is_map(roles)) ->
            grant

          {module, roles, [widen: true]} = grant
          when is_atom(module) and (is_list(roles) or is_map(roles)) ->
            grant

          other ->
            raise ArgumentError, "#{inspect(system)}.grants/0: not a grant: #{inspect(other)}"
        end)

      other ->
        raise ArgumentError,
              "#{inspect(system)}.grants/0 must return a list, got: #{inspect(other)}"
    end
  end

  defp call(system, callback) do
    apply(system, callback, [])
  rescue
    error ->
      reraise ArgumentError,
              "#{inspect(system)}.#{callback}/0 failed: #{Exception.message(error)}",
              __STACKTRACE__
  end

  # The macros run while the router compiles, so they take no compile-time
  # dependency on the SaaS module and its systems.
  # Their source files are external resources instead: editing one recompiles
  # the caller, without connecting the caller to everything the SaaS module
  # names (start pages, menus).
  defp external_resources(systems) do
    sources =
      for module <- [module() | systems],
          do: module.module_info(:compile) |> Keyword.fetch!(:source) |> to_string()

    for source <- [@core_systems_source | sources],
        do: quote(do: @external_resource(unquote(source)))
  end

  @doc false
  # The systems of `saas`, after checking that each entry is a `Mica.System`.
  def checked_systems(saas) do
    ensure_implements!(saas, :systems, "Mica.SaaS", "config :mica, saas:")
    systems = saas.systems()

    for system <- systems do
      ensure_implements!(system, :routes, "Mica.System", "#{inspect(saas)}.systems/0")
    end

    case systems -- Enum.uniq(systems) do
      [] ->
        collect_feature_flags(saas, systems)
        systems

      duplicates ->
        raise ArgumentError,
              "#{inspect(saas)}.systems/0 lists #{inspect(Enum.uniq(duplicates))} more than once"
    end
  end

  # Checked by a callback, not by the behaviour attribute: naming the behaviour
  # module here would make it a dependency of every caller of the macros.
  defp ensure_implements!(module, callback, behaviour, source) do
    case Code.ensure_compiled(module) do
      {:module, ^module} ->
        unless function_exported?(module, callback, 0) do
          raise ArgumentError,
                "#{source} names #{inspect(module)}, which does not `use #{behaviour}`"
        end

      {:error, reason} ->
        raise ArgumentError,
              "#{source} names #{inspect(module)}, which is not a module (#{reason})"
    end
  end
end
