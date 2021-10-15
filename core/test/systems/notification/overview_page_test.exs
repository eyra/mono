defmodule Systems.Notification.OverviewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Systems.Notification.Context

  setup [:login_as_member]

  test "show notifications", %{conn: conn, user: user} do
    title = Faker.Lorem.sentence()
    Context.notify(user, %{title: title})
    {:ok, _view, html} = live(conn, Routes.live_path(conn, Systems.Notification.OverviewPage))
    assert html =~ title
  end
end
