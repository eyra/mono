defmodule CoreWeb.Live.User.Routes do
  defmacro routes() do
    quote do
      scope "/user", Systems.Account do
        pipe_through([:browser])
        get("/onboarding/start", OnboardingController, :start)
      end

      scope "/", Systems.Account do
        pipe_through([:browser, :redirect_if_user_is_authenticated])
        live("/user/signup/:user_type", SignupPage)
        live("/user/confirm/:token", ConfirmToken)
        live("/user/confirm", ConfirmToken)
        live("/user/await-confirmation", AwaitConfirmation)

        live("/user/reset-password", ResetPassword)
        live("/user/reset-password/:token", ResetPasswordToken)
      end

      ## User routes

      scope "/", Systems.Account do
        pipe_through([:browser, :require_authenticated_user])
        live("/user/profile", UserProfilePage)
        live("/user/profile/:tab", UserProfilePage)
        live("/user/onboarding", OnboardingPage)
      end

      scope "/", Systems.Account do
        pipe_through([:browser, :require_authenticated_user])

        get("/user/settings", SettingsController, :edit)
        put("/user/settings", SettingsController, :update)

        get(
          "/user/settings/activate-account/:token",
          SettingsController,
          :activate_account
        )
      end

      scope "/auth", Systems.Account.MockAuth do
        pipe_through([:browser])
        get("/mock", InitiatorPlug, [])
        get("/mock/callback", CallbackController, :authenticate)
      end

      scope "/user/auth", Systems.Account.MockAuth do
        pipe_through([:browser])
        get("/mock/reset", ResetController, :reset)
      end

      scope "/api/service", Systems.Account do
        pipe_through([:api])

        post("/login", ServiceLoginController, :create)
      end
    end
  end
end
