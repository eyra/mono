defmodule Link do
  def routes do
    quote do
      scope "/", Link do
        pipe_through([:browser, :require_authenticated_user])
        live("/dashboard", Dashboard)
      end
    end
  end

  def grants do
    quote do
      grant_access(Link.Dashboard, [:member])
    end
  end
end
