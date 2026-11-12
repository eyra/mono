defmodule Systems.Account.System do
  use Mica.System

  def routes do
    quote do
      pipeline :native_account do
        plug(:accepts, ["json"])
        plug(:fetch_session)
        plug(Systems.Account.Plug)
        plug(:fetch_current_user)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      scope "/user/account/native", Systems.Account do
        pipe_through([:native_account])
        get("/profile", NativeController, :show)
        post("/profile", NativeController, :update)
        post("/photo", NativeController, :photo)
        delete("/session", NativeController, :sign_out)
      end
    end
  end

  def grants do
    [
      {Systems.Account.AwaitConfirmation, [:visitor]},
      {Systems.Account.ConfirmToken, [:visitor]},
      {Systems.Account.Auth.IdentityProviderTransferPage, [:visitor]},
      {Systems.Account.Auth.Mock.SigninPage, [:visitor]},
      {Systems.Account.ResetPassword, [:visitor]},
      {Systems.Account.ResetPasswordToken, [:visitor]},
      {Systems.Account.SignupPage, [:visitor]},
      {Systems.Account.Page, [:member]},
      {Systems.Account.OnboardingPage, [:member]},
      {Systems.Account.UserSecuritySettings, [:member]},
      {Systems.Account.UserSettings, [:member]},
      {Systems.Account.UserSignin, [:visitor]}
    ]
  end

  def signal_handlers, do: [Systems.Account.Switch]

  def account_tabs do
    [
      Systems.Account.ProfileTab,
      Systems.Account.PayoutsTab,
      Systems.Account.FeaturesTab
    ]
  end

  # Prune auth codes past their validity window every hour
  def oban_crons, do: [auth_code_cleanup: {"0 * * * *", Systems.Account.AuthCodeCleanupWorker}]

  def rate_quotas do
    [
      [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local],
      [service: :otp_request, limit: 3, unit: :call, window: :minute, scope: :local]
    ]
  end

  def feature_flags, do: [:centerdata_sign_in, :member_google_sign_in, :password_sign_in]
end
