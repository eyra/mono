defmodule Systems.Pool.PanlSignupTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Pool
  alias Systems.Account

  describe "PANL pool signup integration" do
    setup do
      panl_pool = Core.Factories.insert!(:pool, %{name: "Panl", director: :citizen})
      {:ok, panl_pool: panl_pool}
    end

    defp create_confirmed_user(email, creator) do
      password = Factories.valid_user_password()

      user =
        Factories.insert!(:member, %{
          email: email,
          password: password,
          creator: creator,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      {user, password}
    end

    defp assert_signup_page_loads(conn, user_type) do
      conn = get(conn, ~p"/user/signup/#{user_type}?post_signup_action=add_to_panl")
      response = html_response(conn, 200)
      assert response =~ "Create an account"
      assert response =~ "phx-submit=\"signup\""
    end

    defp perform_signin(conn, email, password, action \\ "add_to_panl") do
      post(conn, ~p"/user/session", %{
        "email" => email,
        "password" => password,
        "post_signin_action" => action
      })
    end

    test "signup pages load correctly with add_to_panl parameter", %{conn: conn} do
      # Both participant and creator signup pages should load (restriction is server-side)
      assert_signup_page_loads(conn, "participant")
      assert_signup_page_loads(conn, "creator")
    end

    test "signin behavior with add_to_panl parameter", %{conn: conn, panl_pool: pool} do
      {participant, participant_password} =
        create_confirmed_user("participant@example.com", false)

      creator_password = Factories.valid_user_password()

      creator_params = %{
        "email" => "creator@example.com",
        "password" => creator_password,
        "creator" => true
      }

      {:ok, creator} = Account.Public.register_user(creator_params)

      refute Pool.Public.participant?(pool, participant)
      conn = perform_signin(conn, "participant@example.com", participant_password)
      assert redirected_to(conn) =~ "/"
      assert Pool.Public.participant?(pool, participant)

      refute Pool.Public.participant?(pool, creator)
      conn = perform_signin(conn, "creator@example.com", creator_password)
      assert redirected_to(conn) =~ "/"
      refute Pool.Public.participant?(pool, creator)
    end

    test "signin edge cases", %{conn: conn, panl_pool: pool} do
      {user, user_password} = create_confirmed_user("test@example.com", false)

      refute Pool.Public.participant?(pool, user)
      conn = perform_signin(conn, "test@example.com", "WrongPassword")
      assert redirected_to(conn) =~ "/user/signin"
      refute Pool.Public.participant?(pool, user)

      conn = perform_signin(conn, "test@example.com", user_password, "false")
      assert redirected_to(conn) =~ "/"
      refute Pool.Public.participant?(pool, user)

      # Already in pool should remain in pool (idempotent)
      Pool.Public.add_participant!(pool, user)
      assert Pool.Public.participant?(pool, user)
      conn = perform_signin(conn, "test@example.com", user_password)
      assert redirected_to(conn) =~ "/"
      assert Pool.Public.participant?(pool, user)
    end

    test "PANL pool operations", %{panl_pool: panl_pool} do
      pool = Pool.Public.get_panl()
      assert pool != nil
      assert pool.name == "Panl"

      user = Core.Factories.insert!(:member)
      refute Pool.Public.participant?(panl_pool, user)
      Pool.Public.add_participant!(panl_pool, user)
      assert Pool.Public.participant?(panl_pool, user)
    end

    test "Google signin URL includes add_to_panl parameter", %{conn: conn} do
      conn = get(conn, ~p"/user/signin/participant?post_signin_action=add_to_panl")
      response = html_response(conn, 200)
      assert response =~ "/google-sign-in?post_signin_action=add_to_panl&amp;creator=false"
    end
  end
end
