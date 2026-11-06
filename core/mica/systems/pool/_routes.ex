defmodule Systems.Pool.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Pool do
        pipe_through([:browser, :require_authenticated_member])
        get("/pool/:slug/join", Controller, :join)
        live("/pool/:slug/onboarding", OnboardingPage)
        live("/pool/:id", LandingPage)
        live("/pool/:id/marketplace", MarketplacePage)
      end

      scope "/", Systems.Pool do
        pipe_through([:browser, :require_authenticated_user])
        live("/pool/:id/content", ContentPage)
        live("/pool/:id/detail", DetailPage)
        live("/pool/advert/:id", SubmissionPage)
        live("/pool/participant/:id", ParticipantPage)
      end
    end
  end
end
