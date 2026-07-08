defmodule Systems.Pool.ControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Pool
  alias Core.Factories

  # The controller looks up pools via `Pool.Public.get_by_slug/1`, which
  # takes an atom slug. `String.to_existing_atom/1` requires the atom to
  # already be registered — `:panl` is safe here because
  # `Systems.Pool.AccountPostActionHandler` references it at compile time.
  defp panl_pool, do: Factories.insert!(:pool, %{name: "Panl", director: :citizen})

  describe "GET /pool/:slug/join" do
    setup [:login_as_member]

    test "redirects non-participants to the pool onboarding page", %{conn: conn, user: user} do
      pool = panl_pool()
      refute Pool.Public.participant?(pool, user)

      conn = get(conn, ~p"/pool/panl/join")

      assert redirected_to(conn) == "/pool/panl/onboarding"
    end

    test "redirects existing participants to the home page", %{conn: conn, user: user} do
      pool = panl_pool()
      Pool.Public.add_participant!(pool, user)

      conn = get(conn, ~p"/pool/panl/join")

      # Home lives at "/" for members via Account.UserAuth.signed_in_path/1.
      assert redirected_to(conn) == "/"
    end
  end

  describe "GET /pool/:slug/join without authentication" do
    test "redirects to the signin page", %{conn: conn} do
      conn = get(conn, ~p"/pool/panl/join")

      assert redirected_to(conn) =~ "/user"
    end
  end
end
