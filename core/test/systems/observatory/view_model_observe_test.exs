defmodule Systems.Observatory.ViewModelObserveTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Core.AuthTestHelpers

  alias Systems.{
    Test
  }

  describe "View model roundtrip" do
    setup [:login_as_member]

    test "View model initialize", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Test.Page, 1))

      assert html =~ "John Doe"
      assert html =~ "Age: 56 - Works at: The Basement"
    end

    test "View model update", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Test.Page, 1))

      model = Test.Context.get(1)
      Test.Context.update(model, %{age: 57})

      assert render(view) =~ "Age: 57 - Works at: The Basement"
    end
  end
end
