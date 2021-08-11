defmodule SignInWithApple.FakeBackend do
  def callback(_config, _token) do
    {:ok,
     %{
       user: %{
         "sub" => "test",
         "email" => Faker.Internet.email(),
         "is_private_email" => true
       }
     }}
  end
end

defmodule SignInWithApple.CallbackPlug.Test do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  alias SignInWithApple.CallbackPlug

  setup do
    Application.put_env(:test, SignInWithApple,
      apple_backend_module: SignInWithApple.FakeBackend,
      log_in_user: fn _conn, user, _first_time? -> user end
    )

    :ok
  end

  describe "call/2" do
    test "creates a user" do
      user_data =
        Jason.encode!(%{
          "name" => %{
            "firstName" => Faker.Person.first_name(),
            "middleName" => Faker.Person.first_name(),
            "lastName" => Faker.Person.last_name()
          }
        })

      user =
        conn(:post, "/apple/auth")
        |> Map.put(:body_params, %{
          "id_token" => "whatever",
          "user" => user_data
        })
        |> init_test_session(%{})
        |> CallbackPlug.call(:test)

      assert user.id
    end

    test "authenticates an existing user" do
      email = Faker.Internet.email()

      SignInWithApple.register_user(%{
        sub: "test",
        email: email,
        is_private_email: true,
        first_name: Faker.Person.first_name(),
        middle_name: nil,
        last_name: Faker.Person.last_name()
      })

      user =
        conn(:post, "/apple/auth")
        |> Map.put(:body_params, %{
          "id_token" => "whatever"
        })
        |> init_test_session(%{})
        |> CallbackPlug.call(:test)

      assert user.email == email
    end
  end
end
