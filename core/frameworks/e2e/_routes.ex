defmodule Frameworks.E2E.Routes do
  @moduledoc """
  E2E test routes.

  Requires the :e2e feature to be enabled via ENABLED_APP_FEATURES.
  """

  defmacro routes() do
    quote do
      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api])

        # Public introspection of enabled feature flags — used by E2E test
        # runners to decide which tests to skip. Not feature-gated.
        get("/features", Controller, :features)

        # Bootstrap creates the service user - no auth required, protected by :e2e feature flag
        post("/bootstrap", Controller, :bootstrap)
      end

      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api, :require_authenticated_user])

        post("/setup", Controller, :setup)
      end
    end
  end
end
