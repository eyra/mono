defmodule MockAuthTest do
  use CoreWeb.ConnCase, async: false
  import Frameworks.Signal.TestHelper
  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.Identity.Mock
  alias Systems.Account.User

  setup do
    isolate_signals()

    original_satellites =
      Application.get_env(:core, :account, []) |> Keyword.get(:auth_methods, %{})

    on_exit(fn ->
      put_auth_methods(original_satellites)
    end)

    :ok
  end

  defp put_auth_methods(satellites) do
    account = Application.get_env(:core, :account, [])
    Application.put_env(:core, :account, Keyword.put(account, :auth_methods, satellites))
  end

  defp enable_mock(), do: put_auth_methods(%{mock: %{provider: true, satellite: false}})
  defp disable_mock(), do: put_auth_methods(%{})

  defp insert_mock_user() do
    Factories.insert!(:creator, %{
      email: "example@mock.com",
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
  end

  describe "configured?/0" do
    test "returns true when :mock is in auth_providers" do
      enable_mock()
      assert Systems.Account.Identity.Mock.configured?()
    end

    test "returns false when :mock is not in auth_providers" do
      disable_mock()
      refute Systems.Account.Identity.Mock.configured?()
    end
  end

  describe "SigninPage" do
    test "renders when configured", %{conn: conn} do
      enable_mock()

      {:ok, view, _html} = live(conn, "/auth/mock")
      assert has_element?(view, "[data-testid='mock-auth-signin-page']")
      assert has_element?(view, "[data-testid='mock-auth-email-input'][value='example@mock.com']")
    end
  end

  describe "CallbackController" do
    test "creates a new mock user and redirects to onboarding", %{
      conn: conn
    } do
      enable_mock()
      assert is_nil(Repo.get_by(User, email: "example@mock.com"))

      conn = conn |> get("/auth/mock/callback")

      assert redirected_to(conn) == "/user/onboarding"

      user = Repo.get_by(User, email: "example@mock.com")
      assert user
      assert user.creator == true
      assert user.verified_at != nil
      assert user.confirmed_at == nil
    end

    test "sends an existing mock user to transfer confirmation", %{conn: conn} do
      enable_mock()
      user = insert_mock_user()

      conn = conn |> get("/auth/mock/callback")

      assert redirected_to(conn) == "/auth/mock/transfer"

      assert get_session(conn, :idp_transfer) == %{
               "email" => "example@mock.com",
               "idp" => "mock",
               "user_id" => user.id
             }
    end

    test "uses an @mock.com email selected at the mock sign-in page", %{conn: conn} do
      enable_mock()

      conn = conn |> get("/auth/mock/callback?email=researcher@mock.com")

      assert redirected_to(conn) == "/user/onboarding"
      assert Repo.get_by(User, email: "researcher@mock.com")
    end

    test "rejects a non-mock email", %{conn: conn} do
      enable_mock()

      conn = conn |> get("/auth/mock/callback?email=researcher@example.com")
      assert conn.status == 404
      refute Repo.get_by(User, email: "researcher@example.com")
    end

    test "returns 404 when not configured", %{conn: conn} do
      disable_mock()
      conn = conn |> get("/auth/mock/callback")
      assert conn.status == 404
    end
  end

  describe "ResetController" do
    test "deletes mock user and redirects to /user/auth/identify/mock", %{conn: conn} do
      enable_mock()
      user = insert_mock_user()
      assert Repo.get(User, user.id)

      conn = conn |> get("/user/auth/mock/reset")

      assert redirected_to(conn) == "/user/auth/identify/mock"
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
      assert is_nil(Repo.get_by(User, email: "example@mock.com"))

      conn = conn |> get("/user/auth/mock/reset")
      assert redirected_to(conn) == "/user/auth/identify/mock"
    end

    test "returns 404 when not configured", %{conn: conn} do
      disable_mock()
      conn = conn |> get("/user/auth/mock/reset")
      assert conn.status == 404
    end
  end
end
