defmodule Systems.Project.OverviewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Repo

  describe "login page" do
    setup [:login_as_creator]

    test "render empty", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/project")
      assert html =~ "My first project"
    end

    test "render 1 project", %{conn: conn, user: user} do
      Factories.build(:project, %{
        name: "Appelmoes",
        auth_node:
          Factories.build(:auth_node, %{
            role_assignments: [
              Factories.build(:owner, %{user: user})
            ]
          })
      })
      |> Repo.insert!()

      {:ok, _view, html} = live(conn, ~p"/project")
      assert html =~ "Appelmoes"
    end

    test "create project", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/project")

      refute html =~ "New project\n"
      refute html =~ "New project (2)\n"

      html = render_click(view, "create_project")

      assert html =~ "New project\n"
      refute html =~ "New project (2)\n"

      html = render_click(view, "create_project")

      assert html =~ "New project\n"
      assert html =~ "New project (2)\n"
    end
  end
end
