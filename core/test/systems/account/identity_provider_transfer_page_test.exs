defmodule Systems.Account.IdentityProviderTransferPageTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

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
