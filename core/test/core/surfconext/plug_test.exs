defmodule Core.SurfConext.FakeOIDC do
  def callback(config, _params) do
    sub = Keyword.get(config, :sub, "test")
    token = Keyword.get(config, :token, "test-token")

    {:ok, %{user: %{"sub" => sub}, token: token}}
  end

  def fetch_userinfo(config, "test-token") do
    {:ok, base_user(config)}
  end

  def fetch_userinfo(config, "student-token") do
    user =
      config
      |> base_user()
      |> Map.put("eduperson_affiliation", ["student"])
      |> Map.put("schac_personal_unique_code", [
        "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:1234567"
      ])

    {:ok, user}
  end

  def fetch_userinfo(config, "researcher-token") do
    user =
      config
      |> base_user()
      |> Map.put("eduperson_affiliation", ["employee"])

    {:ok, user}
  end

  defp base_user(config) do
    sub = Keyword.get(config, :sub, "test")

    first_name = Faker.Person.first_name()
    last_name = Faker.Person.last_name()

    %{
      "sub" => sub,
      "email" => Faker.Internet.email(),
      "email_verified" => true,
      "preferred_username" => "#{first_name} #{last_name}",
      "given_name" => first_name,
      "family_name" => last_name,
      "schac_home_organization" => "eduid.nl",
      "updated_at" => 1_615_100_207
    }
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
        redirect_uri: "https://#{domain}/surfconext/auth",
        oidc_module: Core.SurfConext.FakeOIDC
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
      oidc_module: Core.SurfConext.FakeOIDC
    ]

    Application.put_env(:core, Core.SurfConext, test_conf)

    conn = CoreWeb.ConnCase.build_conn()

    {:ok, conn: conn, conf: test_conf}
  end

  describe "authenticate/1" do
    test "creates a user", %{conn: conn} do
      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/console"
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
      assert redirected_to(conn) == "/console"
    end

    test "authenticates an existing researcher", %{conn: conn} do
      email = Faker.Internet.email()

      Core.SurfConext.register_user(%{
        "sub" => "test",
        "email" => email,
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["employee"]
      })

      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/console"
    end

    test "authenticates an existing student", %{conn: conn} do
      email = Faker.Internet.email()

      Core.SurfConext.register_user(%{
        "sub" => "test",
        "email" => email,
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["student"]
      })

      conn = conn |> get("/surfconext/auth")
      assert redirected_to(conn) == "/console"
    end

    test "authenticates new researcher", %{conn: conn, conf: conf} do
      conf =
        conf
        |> Keyword.put(:sub, "researcher")
        |> Keyword.put(:token, "researcher-token")

      Application.put_env(:core, Core.SurfConext, conf)

      conn = conn |> get("/surfconext/auth")
      # no onboarding yet for researchers
      assert redirected_to(conn) == "/console"
    end

    test "authenticates new student", %{conn: conn, conf: conf} do
      conf =
        conf
        |> Keyword.put(:sub, "student")
        |> Keyword.put(:token, "student-token")

      Application.put_env(:core, Core.SurfConext, conf)

      conn = conn |> get("/surfconext/auth")
      # onboarding only on link yet
      assert redirected_to(conn) == "/console"
    end

    test "updates an existing student", %{conn: conn, conf: conf} do
      email = Faker.Internet.email()

      Core.SurfConext.register_user(%{
        "sub" => "student",
        "email" => email,
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["student"]
      })

      conf =
        conf
        |> Keyword.put(:sub, "student")
        |> Keyword.put(:token, "student-token")

      Application.put_env(:core, Core.SurfConext, conf)

      conn = conn |> get("/surfconext/auth")

      user = Core.SurfConext.get_user_by_sub("student")
      surfconext_user = Core.SurfConext.get_surfconext_user_by_user(user)

      assert redirected_to(conn) == "/console"

      assert surfconext_user.schac_personal_unique_code == [
               "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:1234567"
             ]
    end
  end
end
