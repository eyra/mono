# (c) Copyright 2021 Vrije Universiteit Amsterdam, all rights reserved.

defmodule Link do
  def routes do
    quote do
      scope "/", Link do
        pipe_through(:browser)
        live("/", Index)
      end

      scope "/", Link do
        pipe_through([:browser, :require_authenticated_user])
        live("/debug", Debug)
        live("/dashboard", Dashboard)
        live("/onboarding", Onboarding.Wizard)
        live("/studentpool", Pool.Overview)
        live("/marketplace", Marketplace)
        live("/labstudy/all", LabStudy.Overview)
        live("/campaign/all", Survey.Overview)
        live("/campaign/:id/content", Survey.Content)
        live("/campaign/:id/complete", Survey.Complete)
        live("/campaign/:id/submission", Pool.Submission)
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
      grant_access(Link.Survey.Overview, [:member])
      grant_access(Link.Survey.Content, [:owner])
      grant_access(Link.Survey.Complete, [:participant])
      grant_access(Link.Promotion.Public, [:visitor, :member, :owner])
    end
  end
end
