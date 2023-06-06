# (c) Copyright 2021 Vrije Universiteit Amsterdam, all rights reserved.

defmodule Link.Bundle do
  def routes do
    quote do
      scope "/", Link do
        pipe_through([:browser, :redirect_if_user_is_authenticated])
        get("/user/signin", User.SessionController, :new)
        post("/user/signin", User.SessionController, :create)
      end

      scope "/", Link do
        pipe_through([:browser])
        delete("/user/signout", User.SessionController, :delete)
      end

      scope "/", Link do
        pipe_through(:browser)
        live("/", Index.Page)
      end

      scope "/", Link do
        pipe_through([:browser, :require_authenticated_user])
        live("/debug", Debug.Page)
        live("/console", Console.Page)
        live("/onboarding", Onboarding.WizardPage)
        live("/marketplace", Marketplace.Page)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Debug.Page, [:visitor, :member])
      grant_access(Link.Index.Page, [:visitor, :member])
      grant_access(Link.Console.Page, [:member])
      grant_access(Link.Onboarding.WizardPage, [:member])
      grant_access(Link.Marketplace.Page, [:member])
      grant_access(Systems.Promotion.LandingPage, [:visitor, :member, :owner])
    end
  end
end
