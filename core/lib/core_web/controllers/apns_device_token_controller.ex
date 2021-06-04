defmodule CoreWeb.APNSDeviceTokenController do
  use CoreWeb, :controller

  alias Core.APNS

  action_fallback(CoreWeb.FallbackController)

  def create(%{assigns: %{current_user: user}} = conn, %{"device_token" => device_token}) do
    with {:ok, _} <- APNS.register(user, device_token) do
      conn |> resp(:ok, "")
    end
  end
end
