defmodule Systems.Account.ServiceLoginControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Account

  @service_domain "@eyra.service"
  @valid_password "ValidPassword123!"
  @service_key "test-service-key"

  setup do
    # Configure service login key for tests
    Application.put_env(:core, :service_login, key: @service_key)

    on_exit(fn ->
      Application.delete_env(:core, :service_login)
    end)

    :ok
  end

  defp create_service_user(email, password) do
    {:ok, user} =
      Account.Public.register_user(%{
        email: email,
        password: password,
        password_confirmation: password
      })

    # Confirm the user (required for login)
    user
    |> Account.User.confirm_changeset()
    |> Core.Repo.update!()
  end

  describe "POST /api/service/login" do
    test "returns 503 when service login not configured", %{conn: conn} do
      Application.delete_env(:core, :service_login)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", "any-key")
        |> post("/api/service/login", %{email: "test@eyra.service", password: "test"})

      assert json_response(conn, 503) == %{"error" => "Service login not configured"}
    end

    test "returns 403 when service key is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/service/login", %{email: "test@eyra.service", password: "test"})

      assert json_response(conn, 403) == %{"error" => "Invalid service key"}
    end

    test "returns 403 when service key is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", "wrong-key")
        |> post("/api/service/login", %{email: "test@eyra.service", password: "test"})

      assert json_response(conn, 403) == %{"error" => "Invalid service key"}
    end

    test "returns 403 when email domain is not @eyra.service", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{email: "test@example.com", password: "test"})

      assert json_response(conn, 403) == %{"error" => "Not a service account"}
    end

    test "returns 401 when user does not exist", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{
          email: "nonexistent#{@service_domain}",
          password: "test"
        })

      assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
    end

    test "returns 401 when password is invalid", %{conn: conn} do
      email = "testuser#{@service_domain}"
      create_service_user(email, @valid_password)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{email: email, password: "wrong-password"})

      assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
    end

    test "returns 401 when user is not confirmed", %{conn: conn} do
      email = "unconfirmed#{@service_domain}"

      {:ok, _user} =
        Account.Public.register_user(%{
          email: email,
          password: @valid_password,
          password_confirmation: @valid_password
        })

      # User is NOT confirmed

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{email: email, password: @valid_password})

      assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
    end

    test "returns 200 and sets session on successful login", %{conn: conn} do
      email = "valid#{@service_domain}"
      create_service_user(email, @valid_password)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{email: email, password: @valid_password})

      assert json_response(conn, 200) == %{"status" => "ok"}
      assert get_session(conn, :user_token)
    end

    test "returns 400 when email is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{password: "test"})

      assert json_response(conn, 400) == %{"error" => "Missing email or password"}
    end

    test "returns 400 when password is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-service-key", @service_key)
        |> post("/api/service/login", %{email: "test@eyra.service"})

      assert json_response(conn, 400) == %{"error" => "Missing email or password"}
    end
  end
end
