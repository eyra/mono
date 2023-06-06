defmodule Next.Bundle do
  defp include?() do
    Application.fetch_env!(:core, :bundle) == :next
  end

  def routes do
    if include?() do
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
  end

  def grants do
    if include?() do
      quote do
        grant_access(Next.Console.Page, [:member])
      end
    end
  end
end
