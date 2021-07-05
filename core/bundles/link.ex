# (c) Copyright 2021 Vrije Universiteit Amsterdam, all rights reserved.

defmodule Link do
  def routes do
    quote do
      scope "/", Link do
        pipe_through([:browser, :require_authenticated_user])
        live("/dashboard", Dashboard)
        live("/survey/:id/content", Survey.Content)
        live("/survey/:id/complete", Survey.Complete)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Dashboard, [:member])
      grant_access(Link.Survey.Content, [:owner])
      grant_access(Link.Survey.Complete, [:participant])
    end
  end
end
