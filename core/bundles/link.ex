# (c) Copyright 2021 Vrije Universiteit Amsterdam, all rights reserved.

defmodule Link do
  def routes do
    quote do
      scope "/", Link do
        pipe_through(:browser)
        live("/", Index)
      end

      scope "/", Systems do
        pipe_through([:browser, :require_authenticated_user])
        live("/campaign/:id/content", Campaign.ContentPage)
        live("/campaign/:id/complete", Crew.CompletePage)
      end

      scope "/", Link do
        pipe_through([:browser, :require_authenticated_user])
        live("/debug", Debug)
        live("/dashboard", Dashboard)
        live("/onboarding", Onboarding.Wizard)
        live("/studentpool", Pool.OverviewPage)
        live("/marketplace", Marketplace)
        live("/labstudy/all", LabStudy.Overview)
        live("/campaign/all", Survey.Overview)
        live("/campaign/:id/submission", Pool.SubmissionPage)
        live("/promotion/:id", Promotion.Public)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Debug, [:visitor, :member])
      grant_access(Link.Index, [:visitor, :member])
      grant_access(Link.Dashboard, [:researcher])
      grant_access(Link.Onboarding.Wizard, [:member])
      grant_access(Link.Pool.OverviewPage, [:researcher])
      grant_access(Link.Pool.SubmissionPage, [:researcher])
      grant_access(Link.Marketplace, [:member])
      grant_access(Link.LabStudy.Overview, [:researcher])
      grant_access(Systems.Campaign.ContentPage, [:owner])
      grant_access(Systems.Crew.CompletePage, [:participant])
      grant_access(Link.Promotion.Public, [:visitor, :member, :owner])
    end
  end
end
