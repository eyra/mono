defmodule Systems.Pool.MarketplacePageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Pool
  alias Core.Factories

  defp test_pool, do: Factories.insert!(:pool, %{name: "test_pool", director: :citizen})

  describe "GET /pool/:id/marketplace" do
    setup [:login_as_member]

    test "redirects non-participants to the home page", %{conn: conn, user: user} do
      pool = test_pool()
      refute Pool.Public.participant?(pool, user)

      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/pool/#{pool.id}/marketplace")
    end

    test "renders the marketplace for pool participants", %{conn: conn, user: user} do
      pool = test_pool()
      Pool.Public.add_participant!(pool, user)

      assert {:ok, _view, html} = live(conn, ~p"/pool/#{pool.id}/marketplace")
      assert html =~ ~s(data-testid="marketplace")
    end
  end
end
