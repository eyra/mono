defmodule Systems.Account.MockOAuthTest do
  use CoreWeb.ConnCase, async: false
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.MockOAuth
  alias Systems.Account.User

  setup do
    isolate_signals()

    original_providers =
      Application.get_env(:core, :account, []) |> Keyword.get(:oauth_providers, [])

    on_exit(fn ->
      put_oauth_providers(original_providers)
    end)

    :ok
  end

  defp put_oauth_providers(providers) do
    account = Application.get_env(:core, :account, [])
    Application.put_env(:core, :account, Keyword.put(account, :oauth_providers, providers))
  end

  defp enable_mock(), do: put_oauth_providers([:mock])
  defp disable_mock(), do: put_oauth_providers([])

  defp insert_mock_user() do
    Factories.insert!(:creator, %{
      email: "mock@example.com",
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
  end

  describe "configured?/0" do
    test "returns true when :mock is in oauth_providers" do
      enable_mock()
      assert MockOAuth.configured?()
    end

    test "returns false when :mock is not in oauth_providers" do
      disable_mock()
      refute MockOAuth.configured?()
    end
  end

  describe "InitiatorPlug" do
    test "redirects to callback when configured", %{conn: conn} do
      enable_mock()
      conn = conn |> get("/auth/mock")
      assert redirected_to(conn) == "/auth/mock/callback"
    end

    test "returns 404 when not configured", %{conn: conn} do
      disable_mock()
      conn = conn |> get("/auth/mock")
      assert conn.status == 404
    end
  end

  describe "CallbackController" do
    test "creates a new mock user with confirmed_at and redirects to oauth onboarding", %{
      conn: conn
    } do
      enable_mock()
      assert is_nil(Repo.get_by(User, email: "mock@example.com"))

      conn = conn |> get("/auth/mock/callback")

      assert redirected_to(conn) == "/user/oauth/onboarding"

      user = Repo.get_by(User, email: "mock@example.com")
      assert user
      assert user.creator == true
      assert user.confirmed_at != nil
    end

    test "logs in existing mock user and redirects to signed-in page", %{conn: conn} do
      enable_mock()
      insert_mock_user()

      conn = conn |> get("/auth/mock/callback")
      assert redirected_to(conn) == "/project"
    end

    test "returns 404 when not configured", %{conn: conn} do
      disable_mock()
      conn = conn |> get("/auth/mock/callback")
      assert conn.status == 404
    end
  end

  describe "ResetController" do
    test "deletes mock user and redirects to /user/auth/mock", %{conn: conn} do
      enable_mock()
      user = insert_mock_user()
      assert Repo.get(User, user.id)

      conn = conn |> get("/user/auth/mock/reset")

      assert redirected_to(conn) == "/user/auth/mock"
      refute Repo.get(User, user.id)
    end

    test "deletes associated user_features", %{conn: conn} do
      enable_mock()
      user = insert_mock_user()
      assert Repo.get_by(FeaturesModel, user_id: user.id)

      conn |> get("/user/auth/mock/reset")

      refute Repo.get_by(FeaturesModel, user_id: user.id)
    end

    test "is a no-op when no mock user exists", %{conn: conn} do
      enable_mock()
      assert is_nil(Repo.get_by(User, email: "mock@example.com"))

      conn = conn |> get("/user/auth/mock/reset")
      assert redirected_to(conn) == "/user/auth/mock"
    end

    test "returns 404 when not configured", %{conn: conn} do
      disable_mock()
      conn = conn |> get("/user/auth/mock/reset")
      assert conn.status == 404
    end
  end
end
