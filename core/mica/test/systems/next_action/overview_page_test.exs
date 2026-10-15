defmodule Systems.NextAction.OverviewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Systems.NextAction

  defmodule SomeAction do
    @behaviour Systems.NextAction.ViewModel

    @impl Systems.NextAction.ViewModel
    def to_view_model(count, _params) do
      %{
        title: "Test: #{count}",
        description: "Testing",
        cta_label: "Open test",
        cta_action: %{type: :redirect, to: "http://example.org"}
      }
    end
  end

  describe "show the todo screen" do
    setup [:login_as_member]

    test "shows a next action when available", %{conn: conn, user: user} do
      NextAction.Public.create_next_action(user, SomeAction)
      {:ok, _view, html} = live(conn, ~p"/todo")

      assert html =~ "Open test"
    end

    test "is updated when task is added", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/todo")
      assert has_element?(view, "#zero-todos")
      NextAction.Public.create_next_action(user, SomeAction)
      assert render(view) =~ "Open test"
    end

    test "is updated when task is completed", %{conn: conn, user: user} do
      NextAction.Public.create_next_action(user, SomeAction)
      {:ok, view, _html} = live(conn, ~p"/todo")
      NextAction.Public.clear_next_action(user, SomeAction)
      refute has_element?(view, "#next-actions")
    end
  end
end
