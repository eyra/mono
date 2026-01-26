defmodule GoogleSignIn.FakeGoogle do
  @sub Faker.UUID.v4()
  @email Faker.Internet.email()

  def sub, do: @sub
  def email, do: @email

  def callback(_config, _params) do
    given_name = Faker.Person.first_name()
    family_name = Faker.Person.last_name()

    {:ok,
     %{
       user: %{
         "sub" => @sub,
         "name" => "#{given_name} #{family_name}",
         "email" => @email,
         "email_verified" => true,
         "given_name" => given_name,
         "family_name" => family_name,
         "picture" => Faker.Internet.url(),
         "locale" => "en"
       },
       token: "test-token"
     }}
  end

  def authorize_url(config) do
    {:ok, %{url: Keyword.get(config, :site), session_params: %{some: :stuff}}}
  end
end

defmodule GoogleSignIn.AuthorizePlug.Test do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn
  alias GoogleSignIn.AuthorizePlug

  describe "call/1" do
    setup do
      domain = Faker.Internet.domain_name()

      Application.put_env(:test, GoogleSignIn,
        client_id: domain,
        client_secret: Faker.Lorem.sentence(),
        site: "https://connect.test.google_sign_in.nl",
        redirect_uri: "https://#{domain}/google_sign_in/auth",
        google_module: GoogleSignIn.FakeGoogle
      )

      {:ok, domain: domain}
    end

    test "redirects to Google login page" do
      conn =
        conn(:get, "/google")
        |> init_test_session(%{})
        |> AuthorizePlug.call(:test)

      assert conn.private.plug_session["google_sign_in"]
      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "https://connect.test.google_sign_in.nl")
    end

    test "sets :user_return_to session var" do
      conn =
        conn(:get, "/google?return_to=/test")
        |> Plug.Conn.fetch_query_params()
        |> init_test_session(%{})
        |> AuthorizePlug.call(:test)

      assert conn.private.plug_session["user_return_to"] == "/test"
    end
  end
end

defmodule GoogleSignIn.CallbackPlug.Test do
  use ExUnit.Case, async: false
  use Core.DataCase
  import Plug.Test
  import ExUnit.CaptureLog
  use Core.FeatureFlags.Test
  alias GoogleSignIn.CallbackPlug

  setup do
    conf = Application.get_env(:core, :admins, [])

    on_exit(fn ->
      Application.put_env(:core, :admins, conf)
    end)

    domain = Faker.Internet.domain_name()

    Application.put_env(:test, GoogleSignIn,
      client_id: domain,
      client_secret: Faker.Lorem.sentence(),
      site: "https://connect.test.google_sign_in.nl",
      redirect_uri: "https://#{domain}/google_sign_in/auth",
      google_module: GoogleSignIn.FakeGoogle,
      log_in_user: fn _conn, user, _first_time? -> user end
    )

    :ok
  end

  describe "call/1" do
    test "creates a user" do
      user =
        conn(:get, "/google")
        |> init_test_session(%{"google_sign_in" => %{state: "test-state"}})
        |> CallbackPlug.call(:test)

      assert user.id
    end

    test "authenticates an existing user" do
      email = Faker.Internet.email()

      given_name = Faker.Person.first_name()
      family_name = Faker.Person.last_name()

      GoogleSignIn.register_user(
        %{
          "sub" => GoogleSignIn.FakeGoogle.sub(),
          "name" => "#{given_name} #{family_name}",
          "email" => email,
          "email_verified" => true,
          "given_name" => given_name,
          "family_name" => family_name,
          "picture" => Faker.Internet.url(),
          "locale" => "en"
        },
        true
      )

      user =
        conn(:get, "/google")
        |> init_test_session(%{"google_sign_in" => %{state: "test-state"}})
        |> CallbackPlug.call(:test)

      assert user.creator == true
      assert user.email == email
    end

    test "deny member when member login is disabled" do
      set_feature_flag(:member_google_sign_in, false)

      assert catch_throw(
               conn(:get, "/google")
               |> init_test_session(%{"google_sign_in" => %{state: "test-state"}})
               |> CallbackPlug.call(:test)
             ) == "Google login is disabled"
    end

    test "allow admin when member login is disabled" do
      Application.put_env(
        :core,
        :admins,
        Systems.Admin.Public.compile([GoogleSignIn.FakeGoogle.email()])
      )

      set_feature_flag(:member_google_sign_in, false)

      user =
        conn(:get, "/google")
        |> init_test_session(%{"google_sign_in" => %{state: "test-state"}})
        |> CallbackPlug.call(:test)

      assert user.email == GoogleSignIn.FakeGoogle.email()
    end

    test "redirects to signin and logs error when session is missing" do
      log =
        capture_log([level: :error], fn ->
          conn =
            conn(:get, "/google?code=abc&state=xyz")
            |> Map.replace!(:secret_key_base, CoreWeb.Endpoint.config(:secret_key_base))
            |> init_test_session(%{})
            |> Plug.Conn.fetch_query_params()
            |> Phoenix.Controller.fetch_flash([])
            |> CallbackPlug.call(:test)

          assert conn.status == 302
          [location] = Plug.Conn.get_resp_header(conn, "location")
          assert location == "/user/signin"
          assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Sign-in could not be completed"
        end)

      assert log =~ "[error]"
      assert log =~ "[GoogleSignIn] OAuth callback without session state"
    end
  end
end
