defmodule Systems.Account.EmailRouter do
  import Ecto.Query

  alias Core.Repo
  alias Systems.Account
  alias Systems.Account.Auth.Methods

  def route(email) when is_binary(email) do
    case Account.Public.get_user_by_email(email) do
      nil -> route_unknown_email(email)
      user -> identity_provider(user) || :otp
    end
  end

  defp route_unknown_email(email), do: organization_idp(email) || :otp

  # ponytail: returns nil until Next Org domains gain an IdP property.
  defp organization_idp(_email), do: nil

  defp identity_provider(user) do
    Methods.satellite_providers()
    |> Enum.find_value(fn provider ->
      model = Methods.satellite(provider)
      Repo.exists?(from(s in model, where: s.user_id == ^user.id)) && provider
    end)
  end
end
