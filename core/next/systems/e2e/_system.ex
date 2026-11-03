defmodule Next.Systems.E2E.System do
  @moduledoc """
  The E2E test API (`/api/e2e/*`) that the Playwright suite uses to set up its
  fixtures. The controller answers only when the `:e2e` feature is on.
  """
  use Mica.System

  def routes do
    quote do
      scope "/api/e2e", Next.Frameworks.E2E do
        pipe_through([:api])

        # Bootstrap creates the service user - no auth required, protected by :e2e feature flag
        post("/bootstrap", Controller, :bootstrap)
        post("/activate_user", Controller, :activate_user)
      end

      scope "/api/e2e", Next.Frameworks.E2E do
        pipe_through([:api, :require_authenticated_user])

        post("/setup", Controller, :setup)
      end
    end
  end

  def feature_flags, do: [:e2e]
end
