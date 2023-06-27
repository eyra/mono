defmodule Port.Bundle do
  defp include?() do
    Application.fetch_env!(:core, :bundle) == :port
  end

  def routes do
    if include?() do
      quote do
        scope "/", Port do
          pipe_through([:browser])
          get("/", Home.LandingPageController, :show)
        end

        scope "/", Port do
          pipe_through([:browser, :redirect_if_user_is_authenticated])
          get("/user/session", User.SessionController, :new)
          post("/user/session", User.SessionController, :create)
        end

        scope "/", Port do
          pipe_through([:browser])
          delete("/user/session", User.SessionController, :delete)
        end

        scope "/", Port do
          pipe_through([:browser, :require_authenticated_user])
          live("/console", Console.Page)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Port.Console.Page, [:member])
      end
    end
  end
end
