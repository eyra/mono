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

  System modules are data modules, read at compile time by the router and
  `Core.Authorization`. Callbacks return quoted code and never call system code.
  `grants/0` is quoted too: a module name used as a value is a runtime
  dependency, and that would make the router recompile whenever any granted page
  changes.

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

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.System

      def override_routes, do: nil
      def routes, do: nil
      def grants, do: quote(do: [])

      defoverridable Core.System
    end
  end
end
