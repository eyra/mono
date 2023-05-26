defmodule Next.Bundle do
  def routes do
    quote do
      scope "/", Next do
        pipe_through([:browser])
        get("/", Home.LandingPageController, :show)
      end

      scope "/", Next do
        pipe_through([:browser, :redirect_if_user_is_authenticated])
        get("/user/signin", User.SessionController, :new)
        post("/user/signin", User.SessionController, :create)
      end

      scope "/", Next do
        pipe_through([:browser])
        delete("/user/signout", User.SessionController, :delete)
      end

      scope "/", Next do
        pipe_through([:browser, :require_authenticated_user])
        live("/console", Console.Page)
      end
    end
  end

  def grants do
    quote do
      grant_access(Next.Console.Page, [:member])
    end
  end
end
