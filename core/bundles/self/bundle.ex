defmodule Self.Bundle do
  defp include?() do
    Application.fetch_env!(:core, :bundle) == :self
  end

  def routes do
    if include?() do
      quote do
        scope "/", Self do
          pipe_through([:browser, :redirect_if_user_is_authenticated])
          live("/user/signin", Account.SigninPage)
          get("/user/session", Account.SessionController, :new)
          post("/user/session", Account.SessionController, :create)
        end

        scope "/", Self do
          pipe_through([:browser])
          delete("/user/session", Account.SessionController, :delete)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Self.Account.SigninPage, [:visitor, :member])
      end
    end
  end
end
