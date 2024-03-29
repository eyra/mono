defmodule CoreWeb.Live.User.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :redirect_if_user_is_authenticated])
        live("/user/signup", User.Signup)
        live("/user/confirm/:token", User.ConfirmToken)
        live("/user/confirm", User.ConfirmToken)
        live("/user/await-confirmation", User.AwaitConfirmation)

        live("/user/reset-password", User.ResetPassword)
        live("/user/reset-password/:token", User.ResetPasswordToken)
      end

      ## User routes

      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/user/profile", User.Profile)
        get("/user/settingscontroller", UserSettingsController, :edit)
        put("/user/settingscontroller", UserSettingsController, :update)

        get(
          "/user/settingscontroller/confirm-email/:token",
          UserSettingsController,
          :confirm_email
        )
      end
    end
  end
end
