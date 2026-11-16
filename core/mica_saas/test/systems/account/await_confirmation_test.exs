defmodule MicaSaas.Systems.Account.AwaitConfirmationTest do
  use MicaSaasWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  test "render", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~m"/user/onboarding/await-confirmation")
    assert html =~ "Activate your account"
  end
end
