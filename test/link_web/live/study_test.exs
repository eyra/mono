defmodule LinkWeb.Live.Study.New.Test do
  use LinkWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Ecto.Query
  alias LinkWeb.Study
  alias Link.Factories

  defp login(user, %{conn: conn}) do
    conn =
      post(conn, Routes.pow_session_path(conn, :create),
        user: %{email: user.email, password: "S4p3rS3cr3t"}
      )

    {:ok, conn: conn, user: user}
  end

  defp login_as_member(ctx) do
    Factories.insert!(:member) |> login(ctx)
  end

  defp login_as_researcher(ctx) do
    Factories.insert!(:researcher) |> login(ctx)
  end

  describe "as a researcher" do
    setup [:login_as_researcher]

    test "create a study", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Study.New))
      title = Faker.Lorem.sentence()
      description = Faker.Lorem.sentence()

      view
      |> element("form")
      |> render_submit(%{study: %{title: title, description: description}})

      new_study = Link.Repo.one(from s in Link.Studies.Study, order_by: s.inserted_at, limit: 1)
      assert_redirect(view, "/studies/#{new_study.id}")
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
