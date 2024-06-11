defmodule CoreWeb.Live.User.Routes do
  defmacro routes() do
    quote do
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
      end

      scope "/", Systems.Account do
        pipe_through([:browser, :require_authenticated_user])

        get("/user/settings", SettingsController, :edit)
        put("/user/settings", SettingsController, :update)

        get(
          "/user/settings/confirm-email/:token",
          SettingsController,
          :confirm_email
        )
      end
    end
  end
end
