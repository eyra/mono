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

  @doc "The systems the SaaS is made of: `Core.SaaS.mica_systems() ++` its own systems."
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

  @optional_callbacks title: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.SaaS

      def title, do: "Mica"

      defoverridable title: 0
    end
  end

  @saas Application.compile_env(:core, :saas)

  # Mix checks compile_env, but does not recompile when only an env var (BUNDLE)
  # changed the value; this recompiles Core.SaaS and so the router and authorization.
  def __mix_recompile__?, do: Application.get_env(:core, :saas) != @saas

  @doc """
  Mica's own systems, the start of every `c:systems/0`. Routes are spliced in
  this order. Keep it a literal list. It lives here and not in `Core`, which
  hundreds of modules `use`: they would all recompile when a system module changes.
  """
  def mica_systems do
    [
      Systems.Admin.System,
      Systems.Advert.System,
      Systems.Affiliate.System,
      Systems.Alliance.System,
      Systems.Assignment.System,
      Systems.Fund.System,
      Systems.Desktop.System,
      Systems.Document.System,
      Systems.Feldspar.System,
      Systems.Home.System,
      Systems.Lab.System,
      Systems.Manual.System,
      Systems.NextAction.System,
      Systems.Payment.System,
      Systems.Org.System,
      Systems.Pool.System,
      Systems.Project.System,
      Systems.Promotion.System,
      Systems.Storage.System,
      Systems.Support.System,
      Systems.Account.System
    ]
  end

  @doc "The configured SaaS module."
  def module, do: @saas || raise(ArgumentError, not_configured())

  def systems, do: module().systems()

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
    for module <- [module() | systems] do
      source = module.module_info(:compile) |> Keyword.fetch!(:source) |> to_string()
      quote do: @external_resource(unquote(source))
    end
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

  defp not_configured do
    "config :core, saas: is not set; the SaaS config (next/config/config.exs, " <>
      "mica_saas/config/config.exs) names the SaaS module"
  end
end
