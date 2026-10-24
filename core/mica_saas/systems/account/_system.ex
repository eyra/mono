defmodule Self.Account.System do
  @moduledoc "Self's sign-in pages, which shadow Mica's sign-in routes."
  use Core.System

  def override_routes do
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

  def grants do
    quote do
      [
        {Self.Account.SigninPage, [:visitor, :user]},
        {Self.Account.AuthIdentifyPage, [:visitor, :user]},
        {Self.Account.AuthCodeVerifyPage, [:visitor, :user]}
      ]
    end
  end
end
