defmodule Systems.NextAction.OverviewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Systems.NextAction
  alias Systems.NextAction.OverviewPage

  defmodule SomeAction do
    @behaviour Systems.NextAction.ViewModel

    @impl Systems.NextAction.ViewModel
    def to_view_model(_url_resolver, count, _params) do
      %{
        title: "Test: #{count}",
        description: "Testing",
        cta: "Open test",
        url: "http://example.org"
      }
    end
  end

  describe "show the todo screen" do
    setup [:login_as_member]

    test "shows a next action when available", %{conn: conn, user: user} do
      NextAction.Context.create_next_action(user, SomeAction)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, OverviewPage))

      assert html =~ "Open test"
    end

    test "is updated when task is added", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, OverviewPage))
      assert has_element?(view, "#zero-todos")
      NextAction.Context.create_next_action(user, SomeAction)
      assert render(element(view, "#next-actions")) =~ "Open test"
    end

    test "is updated when task is completed", %{conn: conn, user: user} do
      NextAction.Context.create_next_action(user, SomeAction)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, OverviewPage))
      NextAction.Context.clear_next_action(user, SomeAction)
      refute has_element?(view, "#next-actions")
    end
  end
end
