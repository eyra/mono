defmodule Systems.Account.System do
  use Core.System

  def grants do
    quote do
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
  end

  def signal_handlers, do: [Systems.Account.Switch]
end
