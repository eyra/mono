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
          live("/user/auth/identify", Account.AuthIdentifyPage, :creator, as: :auth_identify)

          live("/user/auth/identify/participant", Account.AuthIdentifyPage, :participant,
            as: :auth_identify
          )

          live("/user/auth/verify", Account.AuthCodeVerifyPage)
          get("/user/session", Account.SessionController, :new)
          post("/user/session", Account.SessionController, :create)
        end

        scope "/", Next do
          pipe_through([:browser])
          get("/user/auth/redeem", Account.SessionController, :redeem_otp)
          get("/user/auth/status", Account.SessionController, :status)
          delete("/user/session", Account.SessionController, :delete)
        end

        scope "/", Next do
          pipe_through([:browser, :redirect_if_user_is_authenticated])
          live("/user/auth/:provider", Account.AuthProviderPage)
        end
      end
    end
  end

  def grants do
    if include?() do
      quote do
        grant_access(Next.Account.SigninPage, [:visitor, :user])
        grant_access(Next.Account.AuthProviderPage, [:visitor, :user])
        grant_access(Next.Account.AuthIdentifyPage, [:visitor, :user])
        grant_access(Next.Account.AuthCodeVerifyPage, [:visitor, :user])
      end
    end
  end
end
