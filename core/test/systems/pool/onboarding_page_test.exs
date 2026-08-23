defmodule Systems.Pool.OnboardingPageTest do
  # async: false — same reason as PanlSignupTest: this exercises the global
  # `Pool.Public.get_by_slug/1` lookup on a fixed-name "Panl" pool.
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Systems.Pool

  setup [:login_as_member]

  setup do
    pool = Factories.insert!(:pool, %{name: "Panl", director: :citizen})
    {:ok, pool: pool}
  end

  describe "mount as non-participant" do
    test "renders the join consent view first", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      assert view |> has_element?("[data-testid='pool-join-consent-view']")
    end

    test "does not render the features view yet", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      refute view |> has_element?("[data-testid='features-view']")
    end
  end

  describe "mount as existing participant" do
    setup %{user: user, pool: pool} do
      Pool.Public.add_participant!(pool, user)
      :ok
    end

    test "renders the already-member info view (not the join prompt)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      assert view |> has_element?("[data-testid='pool-already-member-view']")
      refute view |> has_element?("[data-testid='pool-join-consent-view']")
    end

    test "home button on the info view redirects to home", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      assert {:error, {:live_redirect, %{to: "/"}}} = render_click(view, "continue")
    end
  end

  # Accept goes through JoinConsentView -> LiveNest publish_event ->
  # parent `handle_info` -> `consume_event`, so any downstream navigation
  # lands *after* `render_click` returns. A subsequent `render/1` flushes
  # the async chain.
  describe "join consent accepted" do
    test "adds the user as a participant", %{conn: conn, user: user, pool: pool} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      refute Pool.Public.participant?(pool, user)

      view
      |> element("[data-testid='pool-join-consent-accept-button']")
      |> render_click()

      # Sync the parent LV: `render_click` returns before the async
      # `handle_info` -> `consume_event` chain runs `add_participant!`.
      render(view)

      assert Pool.Public.participant?(pool, user)
    end

    test "advances to the features step (does not redirect)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      view
      |> element("[data-testid='pool-join-consent-accept-button']")
      |> render_click()

      # After async consume_event, the features view should be rendered
      # and the join consent view should be gone.
      html = render(view)
      assert html =~ ~s(data-testid="features-view")
      refute html =~ ~s(data-testid="pool-join-consent-view")
    end
  end

  describe "join consent has no decline action" do
    test "does not render a decline button (users hit browser Back to exit)",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      refute view |> has_element?("[data-testid='pool-join-consent-decline-button']")
    end
  end

  describe "join consent renders the pool icon" do
    test "shows the pool avatar next to the title", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/pool/panl/onboarding")

      assert html =~ ~s(src="/images/logos/pools/panl_wide.svg")
    end
  end

  describe "features step" do
    test "continue on features redirects to home (last step)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pool/panl/onboarding")

      # Advance to features by accepting the consent.
      view
      |> element("[data-testid='pool-join-consent-accept-button']")
      |> render_click()

      # Send "continue" straight to the parent LiveView. `element/2 +
      # render_click` would traverse the FeaturesView's rendered form
      # elements, one of which trips LazyHTML's CSS parser via an
      # empty `phx-target`. The handle_event is a plain page event so
      # dispatching by name is equivalent.
      assert {:error, {:live_redirect, %{to: "/"}}} = render_click(view, "continue")
    end
  end
end
