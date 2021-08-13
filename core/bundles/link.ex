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
        live("/profile", User.Web.Profile)
        live("/dashboard", Dashboard)
        live("/onboarding", Onboarding)
        live("/studentpool", StudentPool)
        live("/marketplace", Marketplace)
        live("/labstudy/all", LabStudy.Overview)
        live("/survey/all", Survey.Overview)
        live("/survey/:id/content", Survey.Content)
        live("/survey/:id/complete", Survey.Complete)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Index, [:visitor, :member])
      grant_access(Link.User.Web.Profile, [:member])
      grant_access(Link.Dashboard, [:researcher])
      grant_access(Link.Onboarding, [:member])
      grant_access(Link.StudentPool, [:researcher])
      grant_access(Link.Marketplace, [:member])
      grant_access(Link.LabStudy.Overview, [:researcher])
      grant_access(Link.Survey.Overview, [:member])
      grant_access(Link.Survey.Content, [:owner])
      grant_access(Link.Survey.Complete, [:participant])
    end
  end
end
