defmodule Systems.Account.Auth.IdentityProviderTransferPageTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Core.{Factories, Repo}
  alias Systems.Account.Auth.{Email, Google, Surfconext}

  test "renders the transfer details from the pending transition", %{conn: conn} do
    conn =
      Phoenix.ConnTest.init_test_session(conn, %{
        "idp_transfer" => %{"idp" => "surfconext", "email" => "john@doe.nl"}
      })

    {:ok, view, _html} = live(conn, "/auth/surfconext/transfer")

    assert has_element?(view, "[data-testid='idp-transfer-page']", "Transfer authentication")

    assert has_element?(
             view,
             "[data-testid='idp-transfer-page']",
             "We detected you have an existing account with email address john@doe.nl"
           )
  end

  for {idp, provider, userinfo} <- [
        {"google", Google, %{"sub" => "google-transfer-sub"}},
        {"surfconext", Surfconext,
         %{"email" => "surfconext-transfer@example.com", "sub" => "surfconext-transfer-sub"}}
      ] do
    test "confirming #{idp} replaces existing authentication satellites", %{conn: conn} do
      user = Factories.insert!(:member)
      Factories.insert!(:email_user, %{user_id: user.id})

      conn =
        Phoenix.ConnTest.init_test_session(conn, %{
          "idp_transfer" => %{
            "idp" => unquote(idp),
            "user_id" => user.id,
            "userinfo" => unquote(Macro.escape(userinfo))
          }
        })
        |> post("/auth/#{unquote(idp)}/transfer/confirm")

      assert conn.status == 302
      refute get_session(conn, :idp_transfer)
      assert unquote(provider).get(user)
      refute Repo.get_by(Email.UserModel, user_id: user.id)
    end
  end

  test "declining clears the pending transfer", %{conn: conn} do
    conn =
      Phoenix.ConnTest.init_test_session(conn, %{
        "idp_transfer" => %{"idp" => "mock", "email" => "example@mock.com"}
      })

    conn = post(conn, "/auth/mock/transfer/decline")

    assert redirected_to(conn) == "/user/auth/identify"
    refute get_session(conn, :idp_transfer)
  end
end
