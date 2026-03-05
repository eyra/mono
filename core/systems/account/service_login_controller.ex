defmodule Systems.Account.ServiceLoginController do
  use CoreWeb, {:controller, [formats: [:json]]}

  alias Systems.Account

  @service_domain "@eyra.service"

  @doc """
  API endpoint for service account login.

  POST /api/service/login
  Header: X-Service-Key: <SERVICE_LOGIN_KEY env var>
  Body: {"email": "...", "password": "..."}

  Security layers:
  1. X-Service-Key header must match SERVICE_LOGIN_KEY env var
  2. Email must end with #{@service_domain}
  3. Valid password required

  Returns 200 with session cookie on success, 401/403 on failure.
  """
  def create(conn, %{"email" => email, "password" => password}) when is_binary(email) and is_binary(password) do
    with :ok <- verify_service_key(conn),
         :ok <- verify_service_domain(email) do
      authenticate(conn, email, password)
    else
      {:error, status, message} ->
        conn
        |> put_status(status)
        |> json(%{error: message})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing email or password"})
  end

  defp verify_service_key(conn) do
    expected_key = Application.get_env(:core, :service_login, [])[:key]
    provided_key = conn |> get_req_header("x-service-key") |> List.first()

    cond do
      is_nil(expected_key) or expected_key == "" ->
        {:error, 503, "Service login not configured"}

      provided_key == expected_key ->
        :ok

      true ->
        {:error, 403, "Invalid service key"}
    end
  end

  defp verify_service_domain(email) do
    if String.ends_with?(email, @service_domain) do
      :ok
    else
      {:error, 403, "Not a service account"}
    end
  end

  defp authenticate(conn, email, password) do
    case Account.Public.get_user_by_email_and_password(email, password) do
      %Account.User{} = user ->
        conn
        |> Account.UserAuth.log_in_user_without_redirect(user)
        |> json(%{status: "ok"})

      _ ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid credentials"})
    end
  end
end
