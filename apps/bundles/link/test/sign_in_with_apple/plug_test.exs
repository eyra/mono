defmodule SignInWithApple.FakeBackend do
  def validate_id_token(_config, _token) do
    {:ok,
     %{
       claims: %{
         "sub" => "test",
         "email" => Faker.Internet.email(),
         "is_private_email" => true
       }
     }}
  end
end

defmodule SignInWithApple.CallbackPlug.Test do
  use ExUnit.Case, async: true
  use Link.DataCase
  use Plug.Test
  alias SignInWithApple.CallbackPlug

  setup do
    config = [apple_backend_module: SignInWithApple.FakeBackend]

    {:ok, config: config}
  end

  describe "call/1" do
    test "creates a user", %{config: config} do
      user_data =
        Jason.encode!(%{
          "name" => %{
            "firstName" => Faker.Person.first_name(),
            "middleName" => Faker.Person.first_name(),
            "lastName" => Faker.Person.last_name()
          }
        })

      conn =
        conn(:post, "/apple/auth")
        |> Map.put(:body_params, %{
          "id_token" => "whatever",
          "user" => user_data
        })
        |> init_test_session(%{})
        |> CallbackPlug.call(config)

      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "/")
      assert get_session(conn, :user_token)
    end

    test "authenticates an existing user", %{config: config} do
      email = Faker.Internet.email()

      SignInWithApple.register_user(%{
        sub: "test",
        email: email,
        is_private_email: true,
        first_name: Faker.Person.first_name(),
        middle_name: nil,
        last_name: Faker.Person.last_name()
      })

      conn =
        conn(:post, "/apple/auth")
        |> Map.put(:body_params, %{
          "id_token" => "whatever"
        })
        |> init_test_session(%{})
        |> CallbackPlug.call(config)

      assert conn.status == 302
      [location] = get_resp_header(conn, "location")
      assert String.starts_with?(location, "/")
      session_token = get_session(conn, :user_token)
      user = Link.Accounts.get_user_by_session_token(session_token)
      assert user.email == email
    end
  end
end
