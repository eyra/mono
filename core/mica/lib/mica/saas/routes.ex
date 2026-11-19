defmodule Mica.SaaS.Routes do
  @moduledoc """
  Splices the routes of a SaaS's systems into the SaaS's router:

      defmodule NextWeb.Router do
        use NextWeb, :router
        require Mica.SaaS.Routes

        Mica.SaaS.Routes.override_routes(Next.SaaS)
        Mica.SaaS.Routes.system_routes(Next.SaaS)
      end

  Each system offers its routes as quoted blocks (`c:Mica.System.override_routes/0`,
  `c:Mica.System.routes/0`); these macros splice them in `c:Mica.SaaS.systems/0`
  order. The systems are read while the macro expands, so the router is compiled
  against the SaaS it names, not against `config :mica, saas:`.
  """

  # Mica.Systems, by path: naming it here would make it a dependency of the callers.
  @core_systems_source Path.expand("../systems.ex", __DIR__)

  @doc """
  Splices `override_routes/0` of all systems of `saas`, and records their paths
  for `MicaWeb.PathCheck` (a SaaS's own pages that shadow Mica's).
  """
  defmacro override_routes(saas) do
    block = splice(saas!(saas, __CALLER__), :override_routes)

    quote do
      require MicaWeb.PathCheck
      MicaWeb.PathCheck.overrides(do: unquote(block))
    end
  end

  @doc "Splices `routes/0` of all systems of `saas`, in `systems/0` order."
  defmacro system_routes(saas), do: splice(saas!(saas, __CALLER__), :routes)

  # Expanded as inside a function, as Phoenix's `scope` does: the router then
  # takes no compile-time dependency on the SaaS module.
  defp saas!(saas, caller) do
    case Macro.expand(saas, %{caller | function: {:__mica_routes__, 0}}) do
      saas when is_atom(saas) -> saas
      other -> raise ArgumentError, "expected a SaaS module, got: #{Macro.to_string(other)}"
    end
  end

  defp splice(saas, callback) do
    systems = Mica.SaaS.checked_systems(saas)
    body = for system <- systems, code = call(system, callback), code != nil, do: code
    {:__block__, [], external_resources(saas, systems) ++ body}
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
  defp external_resources(saas, systems) do
    sources =
      for module <- [saas | systems],
          do: module.module_info(:compile) |> Keyword.fetch!(:source) |> to_string()

    for source <- [@core_systems_source | sources],
        do: quote(do: @external_resource(unquote(source)))
  end
end
