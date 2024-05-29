defmodule Systems.Notification.OverviewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Systems.Notification.Public

  setup [:login_as_member]

  test "show notifications", %{conn: conn, user: user} do
    title = Faker.Lorem.sentence()
    Public.notify(user, %{title: title})
    {:ok, _view, html} = live(conn, ~p"/notifications")
    assert html =~ title
  end
end
