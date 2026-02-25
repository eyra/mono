defmodule Frameworks.E2E.Routes do
  @moduledoc """
  E2E test routes.

  The endpoint checks prod_env at runtime and returns 403 on production.
  """

  defmacro routes() do
    quote do
      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api])

        # Bootstrap creates the service user - no auth required, protected by prod_env check
        post("/bootstrap", Controller, :bootstrap)
      end

      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api, :require_authenticated_user])

        post("/setup", Controller, :setup)
      end
    end
  end
end
