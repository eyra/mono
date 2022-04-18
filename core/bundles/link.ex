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
        live("/console", Console)
        live("/onboarding", Onboarding.Wizard)
        live("/marketplace", Marketplace)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Debug, [:visitor, :member])
      grant_access(Link.Index, [:visitor, :member])
      grant_access(Link.Console, [:member])
      grant_access(Link.Onboarding.Wizard, [:member])
      grant_access(Link.Marketplace, [:member])
      grant_access(Systems.Promotion.LandingPage, [:visitor, :member, :owner])
    end
  end
end
