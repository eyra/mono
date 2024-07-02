defmodule Core.APNS do
  @moduledoc """
  The APNS context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Core.Repo
  alias Systems.Account.User

  alias Core.APNS.DeviceToken

  def get_push_tokens(%User{} = user) do
    from(dt in DeviceToken, where: dt.user_id == ^user.id)
    |> Repo.all()
  end

  def register(user, device_token) do
    %DeviceToken{}
    |> DeviceToken.changeset(%{device_token: device_token, user: user})
    |> Repo.insert(on_conflict: :nothing)
  end

  def send_notification(%User{} = user, message) do
    for token <- get_push_tokens(user) do
      send_notification(token, message)
    end

    :ok
  end

  def send_notification(%DeviceToken{} = device_token, message) do
    backend().send_notification(%{
      device_token: device_token,
      message: message
    })
    |> handle_push_response()
  end

  defp handle_push_response(:ok), do: nil

  defp handle_push_response(%{response: :bad_device_token, device_token: device_token}) do
    from(dt in DeviceToken, where: dt.device_token == ^device_token)
    |> Repo.delete_all()
  end

  defp handle_push_response(response) do
    Logger.error("Unexpected push error: #{inspect(response)}")
  end

  defp backend, do: Application.get_env(:core, :apns_backend)
end
