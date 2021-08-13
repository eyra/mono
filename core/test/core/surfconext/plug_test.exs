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
  use ExUnit.Case, async: false
  use Plug.Test
  alias Core.SurfConext.AuthorizePlug

  describe "call/1" do
    test "redirects to SurfConext login page" do
      domain = Faker.Internet.domain_name()

      Application.put_env(:test, Core.SurfConext,
        client_id: domain,
        client_secret: Faker.Lorem.sentence(),
        site: "https://connect.test.surfconext.nl",
        redirect_uri: "https://#{domain}/surfconext/auth"
      )

      conn =
        conn(:get, "/surfconext/auth")
        |> init_test_session(%{})
        |> AuthorizePlug.call(:test)

      assert conn.private.plug_session["surfconext"]
      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "https://connect.test.surfconext.nl")
    end
  end
end

defmodule Core.SurfConext.CallbackController.Test do
  use CoreWeb.ConnCase, async: false

  describe "authenticate/1" do
    setup do
      conf = Application.get_env(:core, Core.SurfConext, [])

      on_exit(fn ->
        Application.put_env(:core, Core.SurfConext, conf)
      end)

      domain = Faker.Internet.domain_name()

      test_conf = [
        client_id: domain,
        client_secret: Faker.Lorem.sentence(),
        site: "https://connect.test.surfconext.nl",
        redirect_uri: "https://#{domain}/surfconext/auth",
        # log_in_user: fn _conn, user, _first_time? -> user end,
        oidc_module: Core.SurfConext.FakeOIDC
      ]

      Application.put_env(:core, Core.SurfConext, test_conf)

      {:ok, conn: build_conn(), conf: test_conf}
    end

    test "creates a user", %{conn: conn} do
      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/marketplace"
    end

    test "redirects when the changeset is invalid", %{conn: conn, conf: conf} do
      Application.put_env(
        :core,
        Core.SurfConext,
        Keyword.put(conf, :limit_schac_home_organization, "my-org")
      )

      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/user/signin"

      assert get_flash(conn, :error) =~ "not allowed to authenticate"
    end

    test "authenticates an existing user", %{conn: conn} do
      email = Faker.Internet.email()

      Core.SurfConext.register_user(%{
        "sub" => "test",
        "email" => email,
        "preferred_username" => Faker.Person.name()
      })

      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/marketplace"
    end
  end
end
