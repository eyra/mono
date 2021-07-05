defmodule CoreWeb.Notifications.Test do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Core.NotificationCenter

  setup [:login_as_member]

  test "show notifications", %{conn: conn, user: user} do
    title = Faker.Lorem.sentence()
    NotificationCenter.notify(user, %{title: title})
    {:ok, _view, html} = live(conn, Routes.live_path(conn, CoreWeb.Notifications))
    assert html =~ title
  end
end
