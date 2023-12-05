defmodule Self.Bundle do
  defp include?() do
    Application.fetch_env!(:core, :bundle) == :self
  end

  def routes do
    if include?() do
      quote do
        scope "/", Self do
          pipe_through([:browser, :redirect_if_user_is_authenticated])
          live("/user/signin", User.Signin)
          get("/user/session", User.SessionController, :new)
          post("/user/session", User.SessionController, :create)
        end

        scope "/", Self do
          pipe_through([:browser])
          delete("/user/session", User.SessionController, :delete)
        end

        scope "/", Self do
          pipe_through([:browser, :require_authenticated_user])
          live("/", Console.Page)
          live("/console", Console.Page)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Self.Console.Page, [:member])
        grant_access(Self.User.Signin, [:visitor, :member])
      end
    end
  end
end
