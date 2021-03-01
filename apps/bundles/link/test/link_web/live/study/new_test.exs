defmodule LinkWeb.Live.Study.New.Test do
  use LinkWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Ecto.Query
  alias LinkWeb.Study
  alias Link.Factories

  describe "as a researcher" do
    setup [:login_as_researcher]

    test "create a study", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Study.New))
      title = Faker.Lorem.sentence()
      description = Faker.Lorem.sentence()

      view
      |> element("form")
      |> render_submit(%{study: %{title: title, description: description}})

      new_study =
        Link.Repo.one(from(s in Link.Studies.Study, order_by: [desc: s.inserted_at], limit: 1))

      assert_redirect(view, "/studies/#{new_study.id}/edit")
    end
  end

  describe "as a member" do
    setup [:login_as_member]

    test "disallow members to create a study", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Study.New))
      assert html =~ "Access Denied"
    end
  end
end
