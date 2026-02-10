defmodule Systems.Account.ServiceLoginController do
  use CoreWeb, {:controller, [formats: [:json]]}

  alias Systems.Account

  @doc """
  API endpoint for service account login.

  POST /api/service/login
  Body: {"email": "...", "password": "..."}

  Returns 200 with session cookie on success, 401 on failure.
  """
  def create(conn, %{"email" => email, "password" => password})
      when is_binary(email) and is_binary(password) do
    case Account.Public.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid credentials"})

      user ->
        conn
        |> Account.UserAuth.log_in_user_without_redirect(user)
        |> json(%{status: "ok"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing email or password"})
  end
end
