defmodule Core.SurfConext.FakeOIDC do
  def callback(_config, _params) do
    {:ok, %{user: %{"sub" => "test"}, token: "test-token"}}
  end

  def fetch_userinfo(_config, "test-token") do
    first_name = Faker.Person.first_name()
    last_name = Faker.Person.last_name()

    {:ok,
     %{
       "sub" => "test",
       "email" => Faker.Internet.email(),
       "email_verified" => true,
       "preferred_username" => "#{first_name} #{last_name}",
       "name" => "#{first_name} #{last_name}",
       "nickname" => "#{first_name} #{last_name}",
       "schac_home_organization" => "eduid.nl",
       "updated_at" => 1_615_100_207
     }}
  end

  def authorize_url(config) do
    {:ok, %{url: Keyword.get(config, :site), session_params: %{some: :stuff}}}
  end
end

defmodule Core.SurfConext.AuthorizePlug.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Core.SurfConext.AuthorizePlug

  describe "call/1" do
    test "redirects to SurfConext login page" do
      domain = Faker.Internet.domain_name()

      config = [
        client_id: domain,
        client_secret: Faker.Lorem.sentence(),
        site: "https://connect.test.surfconext.nl",
        redirect_uri: "https://#{domain}/surfconext/auth"
      ]

      conn =
        conn(:get, "/surf")
        |> init_test_session(%{})
        |> AuthorizePlug.call(config)

      assert conn.private.plug_session["surfconext"]
      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "https://connect.test.surfconext.nl/")
    end
  end
end

defmodule Core.SurfConext.CallbackPlug.Test do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  alias Core.SurfConext.CallbackPlug

  setup do
    domain = Faker.Internet.domain_name()

    config = [
      client_id: domain,
      client_secret: Faker.Lorem.sentence(),
      site: "https://connect.test.surfconext.nl",
      redirect_uri: "https://#{domain}/surfconext/auth",
      oidc_module: Core.SurfConext.FakeOIDC
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

      Core.SurfConext.register_user(%{
        "sub" => "test",
        "email" => email,
        "preferred_username" => Faker.Person.name()
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
