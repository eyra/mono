defmodule Core.Mailer do
  use Bamboo.Mailer, otp_app: :core
  import Bamboo.Email
  import Bamboo.Phoenix

  def base_email do
    new_email()
    |> from(Application.fetch_env!(:core, __MODULE__) |> Keyword.fetch!(:default_from_email))
    |> put_layout({Core.Mailer.EmailLayoutView, :email})
  end
end
