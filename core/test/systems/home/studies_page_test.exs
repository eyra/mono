defmodule Systems.Home.StudiesPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Pool
  alias Core.Factories

  defp make_panl_participant(user) do
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)
  end

  describe "GET /studies" do
    setup [:login_as_member]

    test "redirects non-panl members to the home page", %{conn: conn, user: user} do
      refute Pool.Public.participant?(:panl, user)

      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/studies")
    end

    test "renders the marketplace for panl participants", %{conn: conn, user: user} do
      make_panl_participant(user)

      assert {:ok, _view, html} = live(conn, ~p"/studies")
      assert html =~ "Studies"
    end
  end
end
