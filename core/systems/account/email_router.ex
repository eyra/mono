defmodule Systems.Account.EmailRouter do
  import Ecto.Query

  alias Core.Repo
  alias Systems.Account

  def route(email) when is_binary(email) do
    case Account.Public.get_user_by_email(email) do
      nil -> route_unknown_email(email)
      user -> identity_provider(user) || :otp
    end
  end

  defp route_unknown_email(email), do: organization_idp(email) || user_check_idp(email)

  # ponytail: returns nil until Next Org domains gain an IdP property.
  defp organization_idp(_email), do: nil

  defp user_check_idp(email) do
    case Frameworks.UserCheck.check_email(email) do
      {:ok, result} ->
        Systems.Account.AuthMethods.provider_for_mx_provider(result.mx_provider) || :otp

      {:error, _reason} ->
        :otp
    end
  end

  defp identity_provider(user) do
    Systems.Account.AuthMethods.satellite_providers()
    |> Enum.find_value(fn provider ->
      model = Systems.Account.AuthMethods.satellite(provider)
      Repo.exists?(from(s in model, where: s.user_id == ^user.id)) && provider
    end)
  end
end
