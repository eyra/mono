defmodule Frameworks.E2E.Routes do
  @moduledoc """
  E2E test routes.

  Requires the :e2e feature to be enabled via ENABLED_APP_FEATURES.
  """

  defmacro routes() do
    quote do
      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api])

        # Bootstrap creates the service user - no auth required, protected by :e2e feature flag
        post("/bootstrap", Controller, :bootstrap)
        post("/activate_user", Controller, :activate_user)
      end

      scope "/api/e2e", Frameworks.E2E do
        pipe_through([:api, :require_authenticated_user])

        post("/setup", Controller, :setup)
        post("/inject", Controller, :inject)
      end
    end
  end
end
