defmodule CoreWeb.PushSubscriptionController do
  use CoreWeb, :controller

  alias Core.WebPush

  action_fallback(CoreWeb.FallbackController)

  def register(%{assigns: %{current_user: user}} = conn, %{"subscription" => subscription}) do
    {:ok, _} = WebPush.register(user, subscription)
    conn |> json(%{})
  end

  def register(conn, _) do
    conn |> json(%{})
  end

  def vapid_public_key(conn, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(
      200,
      Application.fetch_env!(:web_push_encryption, :vapid_details) |> Keyword.get(:public_key)
    )
  end
end
