defmodule GoogleSignIn.FakeGoogle do
  @sub Faker.UUID.v4()

  def sub, do: @sub

  def callback(_config, _params) do
    given_name = Faker.Person.first_name()
    family_name = Faker.Person.last_name()

    {:ok,
     %{
       user: %{
         "sub" => @sub,
         "name" => "#{given_name} #{family_name}",
         "email" => Faker.Internet.email(),
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
  use Plug.Test
  alias GoogleSignIn.AuthorizePlug

  describe "call/1" do
    test "redirects to SurfConext login page" do
      domain = Faker.Internet.domain_name()

      config = [
        client_id: domain,
        client_secret: Faker.Lorem.sentence(),
        site: "https://connect.test.google_sign_in.nl",
        redirect_uri: "https://#{domain}/google_sign_in/auth",
        google_module: GoogleSignIn.FakeGoogle
      ]

      conn =
        conn(:get, "/surf")
        |> init_test_session(%{})
        |> AuthorizePlug.call(config)

      assert conn.private.plug_session["google_sign_in"]
      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "https://connect.test.google_sign_in.nl")
    end
  end
end

defmodule GoogleSignIn.CallbackPlug.Test do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  alias GoogleSignIn.CallbackPlug

  setup do
    domain = Faker.Internet.domain_name()

    config = [
      client_id: domain,
      client_secret: Faker.Lorem.sentence(),
      site: "https://connect.test.google_sign_in.nl",
      redirect_uri: "https://#{domain}/google_sign_in/auth",
      google_module: GoogleSignIn.FakeGoogle
    ]

    {:ok, config: config}
  end

  describe "call/1" do
    test "creates a user", %{config: config} do
      conn =
        conn(:get, "/surf")
        |> init_test_session(%{})
        |> CallbackPlug.call(config)

      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "/")
      assert get_session(conn, :user_token)
    end

    test "authenticates an existing user", %{config: config} do
      email = Faker.Internet.email()

      given_name = Faker.Person.first_name()
      family_name = Faker.Person.last_name()

      GoogleSignIn.register_user(%{
        "sub" => GoogleSignIn.FakeGoogle.sub(),
        "name" => "#{given_name} #{family_name}",
        "email" => email,
        "email_verified" => true,
        "given_name" => given_name,
        "family_name" => family_name,
        "picture" => Faker.Internet.url(),
        "locale" => "en"
      })

      conn =
        conn(:get, "/surf")
        |> init_test_session(%{})
        |> CallbackPlug.call(config)

      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "/")
      session_token = get_session(conn, :user_token)
      user = Core.Accounts.get_user_by_session_token(session_token)
      assert user.email == email
    end
  end
end
