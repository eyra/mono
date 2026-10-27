defmodule Core.SaaS do
  @moduledoc """
  A SaaS built on Mica, and the composition of the configured one.

  Each SaaS has one module that implements this behaviour (`Next.SaaS`,
  `Self.SaaS`). It lists the systems the SaaS is made of and carries the
  SaaS-level config. The build picks one in its config:

      config :core, saas: Next.SaaS

  The value is read at compile time: the router and `Core.Authorization` splice
  the routes and grants of all systems (`override_routes/0`, `routes/0`,
  `grants/0`). Never set `:saas` in `runtime.exs`; a release refuses to boot
  when it differs from the compiled value.
  """

  @doc "The systems the SaaS is made of: `Core.Systems.all() ++` its own systems."
  @callback systems() :: [module()]

  @doc "The `CoreWeb.StartPageProvider` implementation."
  @callback start_pages() :: module()

  @doc "The `CoreWeb.Menu.ItemsProvider` implementation."
  @callback menu_items() :: module()

  @doc "The menu builder for a layout."
  @callback menu_builder(:workspace | :website | :stripped) :: module()

  @doc "The product name shown in page titles."
  @callback title() :: String.t()

  @doc "Where a user lands after signing in, unless a return path is set."
  @callback signed_in_page(:creator | :member) :: String.t()

  @doc """
  The SaaS defaults of declared feature flags: `[password_sign_in: true]`. Every
  name must be declared by one of its systems (`c:Core.System.feature_flags/0`).
  """
  @callback feature_flags() :: keyword(boolean())

  @optional_callbacks title: 0, feature_flags: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.SaaS

      def title, do: "Mica"
      def feature_flags, do: []

      defoverridable title: 0, feature_flags: 0
    end
  end

  require Core.Env

  @saas Core.Env.compile_env(:saas) ||
          raise(
            "config :core, saas: is not set; the SaaS config (next/config/config.exs, " <>
              "mica_saas/config/config.exs) names the SaaS module"
          )

  # Core.Systems, by path: naming it here would make it a dependency of the callers.
  @core_systems_source Path.expand("systems.ex", __DIR__)

  # Mix checks compile_env, but does not recompile when only an env var (BUNDLE)
  # changed the value; this recompiles Core.SaaS and so the router and authorization.
  def __mix_recompile__?, do: Core.Env.get(:saas) != @saas

  @doc "The configured SaaS module."
  def module, do: @saas

  def systems, do: module().systems()

  @doc "The signal handlers of all systems, sorted by module name."
  def signal_handlers, do: systems() |> Enum.flat_map(& &1.signal_handlers()) |> Enum.sort()

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

  @doc "The children of all systems, in `systems/0` order."
  def children, do: Enum.flat_map(systems(), & &1.children())

  @doc "The Oban queues of all systems. Raises when two systems declare the same queue."
  def oban_queues, do: collect_oban_queues(systems())

  @doc "The default rate quotas of all systems, in `systems/0` order."
  def rate_quotas, do: Enum.flat_map(systems(), & &1.rate_quotas())

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
  # The systems of `saas`, after checking that each entry is a `Core.System`.
  def checked_systems(saas) do
    ensure_implements!(saas, :systems, "Core.SaaS", "config :core, saas:")
    systems = saas.systems()

    for system <- systems do
      ensure_implements!(system, :routes, "Core.System", "#{inspect(saas)}.systems/0")
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
