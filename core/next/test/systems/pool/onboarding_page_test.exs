defmodule Next.Systems.Pool.OnboardingPageTest do
  # Next's pool logos (`config :mica, :pixel, pool_assets:`) on Mica's pool
  # onboarding page. async: false — same reason as PanlSignupTest: this exercises
  # the global `Pool.Public.get_by_slug/1` lookup on a fixed-name "Panl" pool.
  use NextWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  setup [:login_as_member]

  setup do
    pool = Factories.insert!(:pool, %{name: "Panl", director: :citizen})
    {:ok, pool: pool}
  end

  describe "join consent renders the pool icon" do
    test "shows the pool avatar next to the title", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~m"/pool/panl/onboarding")

      assert html =~ ~s(src="/images/logos/pools/panl_wide.svg")
    end
  end
end
