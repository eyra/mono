defmodule Next.Bundle do
  defp include?() do
    Application.fetch_env!(:core, :bundle) == :next
  end

  def routes do
    if include?() do
      quote do
        scope "/", Next do
          pipe_through([:browser, :redirect_if_user_is_authenticated])
          live("/user/signin", Account.SigninPage)
          live("/user/signin/:user_type", Account.SigninPage)
          get("/user/session", Account.SessionController, :new)
          post("/user/session", Account.SessionController, :create)
        end

        scope "/", Next do
          pipe_through([:browser])
          delete("/user/session", Account.SessionController, :delete)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Next.Account.SigninPage, [:visitor, :member])
      end
    end
  end
end
