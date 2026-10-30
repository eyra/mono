defmodule Mica.SaaS do
  @moduledoc """
  A SaaS built on Mica, and the composition of the configured one.

  Each SaaS has one module that implements this behaviour (`Next.SaaS`,
  `MicaSaas.SaaS`). It lists the systems the SaaS is made of and carries the
  SaaS-level config. The build picks one in its config:

      config :mica, saas: Next.SaaS

  The value is read at compile time: the router and `Mica.Authorization` splice
  the routes and grants of all systems (`override_routes/0`, `routes/0`,
  `grants/0`). Never set `:saas` in `runtime.exs`; a release refuses to boot
  when it differs from the compiled value.
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
  The SaaS defaults of declared feature flags: `[password_sign_in: true]`. Every
  name must be declared by one of its systems (`c:Mica.System.feature_flags/0`).
  """
  @callback feature_flags() :: keyword(boolean())

  @optional_callbacks title: 0, sign_in_page: 0, member_sign_in_page: 1, feature_flags: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour Mica.SaaS

      def title, do: "Mica"
      def feature_flags, do: []

      def sign_in_page, do: "/user/signin"

      def member_sign_in_page(_return_to), do: sign_in_page()

      defoverridable title: 0, sign_in_page: 0, member_sign_in_page: 1, feature_flags: 0
    end
  end

  require Mica.Env

  @saas Mica.Env.compile_env(:saas) ||
          raise(
            "config :mica, saas: is not set; the SaaS config (next/config/config.exs, " <>
              "mica_saas/config/config.exs) names the SaaS module"
          )

  # Mica.Systems, by path: naming it here would make it a dependency of the callers.
  @core_systems_source Path.expand("systems.ex", __DIR__)

  # Mix checks compile_env, but does not recompile when only an env var (BUNDLE)
  # changed the value; this recompiles Mica.SaaS and so the router and authorization.
  def __mix_recompile__?, do: Mica.Env.get(:saas) != @saas

  @doc "The configured SaaS module."
  def module, do: @saas

  def systems, do: module().systems()

  @doc """
  The signal handlers of all systems, sorted by module name within the system
  namespaces: a SaaS system's handler (`Next.Systems.<System>.Switch`) sorts as
  `Systems.<System>.Switch`, among Mica's.
  """
  def signal_handlers,
    do: systems() |> Enum.flat_map(& &1.signal_handlers()) |> Enum.sort_by(&handler_order/1)

  defp handler_order(handler) do
    case Module.split(handler) do
      [_saas, "Systems" | rest] -> {Enum.join(["Systems" | rest], "."), inspect(handler)}
      _ -> {inspect(handler), inspect(handler)}
    end
  end

  @doc "The notifiers of all systems, in `systems/0` order."
  def notifiers, do: Enum.flat_map(systems(), & &1.notifiers())

  @doc "The notification channels of all systems. Raises when two systems name the same channel."
  def notify_channels, do: collect_notify_channels(systems())

  @doc "The admin panels of all systems, in `systems/0` order."
  def admin_panels, do: Enum.flat_map(systems(), & &1.admin_panels())

  @doc "The account tabs of all systems, in `systems/0` order."
  def account_tabs, do: Enum.flat_map(systems(), & &1.account_tabs())

  @doc "The Desktop sections of all systems, in `systems/0` order. Raises when two sections have the same id."
  def desktop_sections, do: collect_desktop_sections(systems())

  @doc "The sign-in handoffs of all systems, in `systems/0` order."
  def sign_in_handoffs, do: Enum.flat_map(systems(), & &1.sign_in_handoffs())

  @doc "The children of all systems, in `systems/0` order."
  def children, do: collect_children(systems())

  @doc "The Oban queues of all systems. Raises when two systems declare the same queue."
  def oban_queues, do: collect_oban_queues(systems())

  @doc "The Oban crons of all systems, in `systems/0` order. Raises when two systems declare the same name."
  def oban_crons, do: collect_oban_crons(systems())

  @doc "The default rate quotas of all systems, in `systems/0` order."
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

  @doc false
  def collect_migrations_paths(systems),
    do: Enum.flat_map(systems, &List.wrap(&1.migrations_path()))

  @doc """
  The declared feature flags of all systems, off unless the SaaS turns them on,
  sorted by name. Raises when the SaaS sets a flag that no system declares.
  """
  def feature_flags, do: collect_feature_flags(module(), systems())

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

  @doc """
  The channel names of `notify_channels/0`, sorted, for use at compile time (an
  `Ecto.Enum`). Editing a system recompiles the caller. Like the route and grant
  macros, it compiles the SaaS module and its systems first, so they must not
  depend on the caller at compile time.
  """
  defmacro notify_channel_names do
    systems = checked_systems(module())
    names = systems |> collect_notify_channels() |> Map.keys() |> Enum.sort()
    {:__block__, [], external_resources(systems) ++ [names]}
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

  @doc "Splices `override_routes/0` of all systems."
  defmacro override_routes, do: splice(:override_routes)

  @doc "Splices `routes/0` of all systems, in `systems/0` order."
  defmacro routes, do: splice(:routes)

  @doc "Expands to `grant_access/2` or `grant_actions/2` for every system grant."
  defmacro grants do
    systems = checked_systems(module())

    grants =
      for system <- systems, grant <- system_grants(system) do
        case grant do
          {module, {:%{}, _, _} = action_roles} ->
            quote do: grant_actions(unquote(module), unquote(action_roles))

          {module, roles} ->
            quote do: grant_access(unquote(module), unquote(roles))
        end
      end

    {:__block__, [], external_resources(systems) ++ grants}
  end

  defp splice(callback) do
    systems = checked_systems(module())
    body = for system <- systems, code = call(system, callback), code != nil, do: code
    {:__block__, [], external_resources(systems) ++ body}
  end

  defp system_grants(system) do
    case call(system, :grants) do
      grants when is_list(grants) ->
        Enum.map(grants, fn
          {_module, _roles} = grant ->
            grant

          other ->
            raise ArgumentError,
                  "#{inspect(system)}.grants/0: not a grant: #{Macro.to_string(other)}"
        end)

      other ->
        raise ArgumentError,
              "#{inspect(system)}.grants/0 must return a quoted list, got: #{Macro.to_string(other)}"
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

  # The macros run while the router and authorization compile, so they take no
  # compile-time dependency on the SaaS module and its systems. Their source
  # files are external resources instead: editing one recompiles the caller,
  # without connecting the caller to everything the SaaS module names (start
  # pages, menus).
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
