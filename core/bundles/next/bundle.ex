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
          live("/user/auth/identify", Account.AuthPage)
          live("/user/auth/identify/:provider", Account.AuthSignupPage)
          live("/user/auth/verify", Account.AuthCodeVerifyPage)
          get("/user/session", Account.SessionController, :new)
          post("/user/session", Account.SessionController, :create)
        end

        scope "/", Next do
          pipe_through([:browser])
          get("/user/auth/redeem", Account.SessionController, :redeem_otp)
          delete("/user/session", Account.SessionController, :delete)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Next.Account.SigninPage, [:visitor, :user])
        grant_access(Next.Account.AuthSignupPage, [:visitor, :user])
        grant_access(Next.Account.AuthPage, [:visitor, :user])
        grant_access(Next.Account.AuthCodeVerifyPage, [:visitor, :user])
      end
    end
  end
end
