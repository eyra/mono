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
          live("/user/auth/identify", Account.AuthIdentifyPage, :creator, as: :auth_identify)

          live("/user/auth/identify/participant", Account.AuthIdentifyPage, :participant,
            as: :auth_identify
          )

          live("/user/auth/verify", Account.AuthCodeVerifyPage)
          get("/user/session", Account.SessionController, :new)
          post("/user/session", Account.SessionController, :create)
        end

        scope "/", Self do
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
        grant_access(Self.Account.SigninPage, [:visitor, :user])
        grant_access(Self.Account.AuthIdentifyPage, [:visitor, :user])
        grant_access(Self.Account.AuthCodeVerifyPage, [:visitor, :user])
      end
    end
  end
end
