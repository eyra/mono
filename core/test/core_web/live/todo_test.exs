defmodule CoreWeb.TodoTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Core.NextActions
  alias CoreWeb.Todo

  defmodule SomeAction do
    @behaviour Core.NextActions.ViewModel

    @impl Core.NextActions.ViewModel
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
      NextActions.create_next_action(user, SomeAction)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Todo))

      assert html =~ "Open test"
    end
  end
end
