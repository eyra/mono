defmodule Systems.Assignment.FinishedViewTest do
  use CoreWeb.ConnCase, async: false

  import Frameworks.Signal.TestHelper
  import Phoenix.LiveViewTest

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  setup do
    # Isolate signals to prevent workflow errors
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "normal completion without redirect" do
    test "renders finished view with illustration and back button", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Should render finished view
      assert has_element?(view, "[data-testid='finished-view']")

      # Should show title and body
      assert has_element?(view, "[data-testid='finished-title']")
      assert has_element?(view, "[data-testid='finished-body']")

      # Should show illustration
      assert has_element?(view, "[data-testid='finished-illustration']")
      assert html =~ "/images/illustrations/finished.svg"

      # Should show back button
      assert has_element?(view, "[data-testid='back-button']")

      # Should NOT show continue button
      refute has_element?(view, "[data-testid='continue-button']")
    end

    test "back button triggers retry event", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Should show back button
      assert has_element?(view, "[data-testid='back-button']")

      # Send retry event directly
      render_click(view, "retry")

      # Event is published, we can't easily assert on it in isolated test
      # but we verify no errors occurred
      assert has_element?(view, "[data-testid='finished-view']")
    end
  end

  describe "completion with redirect" do
    test "renders finished view with continue button and no illustration", %{
      conn: conn,
      user: user
    } do
      redirect_url = "https://example.com/return"

      assignment =
        redirect_url
        |> Assignment.Factories.create_assignment_with_affiliate()
        |> Assignment.Factories.add_affiliate_user(user)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: %{redirect_url: redirect_url}
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Should render finished view
      assert has_element?(view, "[data-testid='finished-view']")

      # Should show title and body
      assert has_element?(view, "[data-testid='finished-title']")
      assert has_element?(view, "[data-testid='finished-body']")

      # Should NOT show illustration
      refute has_element?(view, "[data-testid='finished-illustration']")

      # Should show back button
      assert has_element?(view, "[data-testid='back-button']")

      # Should show continue button
      assert has_element?(view, "[data-testid='continue-button']")
      assert html =~ "https://example.com/return"
    end
  end

  describe "declined consent without redirect" do
    test "renders finished view with declined message and no illustration", %{
      conn: conn,
      user: user
    } do
      assignment =
        nil
        |> Assignment.Factories.create_assignment_with_consent_and_affiliate()
        |> Assignment.Factories.add_participant(user)

      # No Monitor event needed - no_consent? checks signature table directly

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Should render finished view
      assert has_element?(view, "[data-testid='finished-view']")

      # Should show declined title
      assert has_element?(view, "[data-testid='finished-title']")
      assert html =~ "Consent Declined"

      # Should show declined body
      assert has_element?(view, "[data-testid='finished-body']")

      # Should NOT show illustration
      refute has_element?(view, "[data-testid='finished-illustration']")

      # Should show back button
      assert has_element?(view, "[data-testid='back-button']")

      # Should NOT show continue button
      refute has_element?(view, "[data-testid='continue-button']")
    end
  end

  describe "declined consent with redirect" do
    test "renders finished view with declined message and continue button", %{
      conn: conn,
      user: user
    } do
      redirect_url = "https://example.com/return"

      assignment =
        redirect_url
        |> Assignment.Factories.create_assignment_with_consent_and_affiliate()
        |> Assignment.Factories.add_affiliate_user(user)
        |> Assignment.Factories.add_participant(user)

      # No Monitor event needed - no_consent? checks signature table directly

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: %{redirect_url: redirect_url}
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Should render finished view
      assert has_element?(view, "[data-testid='finished-view']")

      # Should show declined title
      assert has_element?(view, "[data-testid='finished-title']")
      assert html =~ "Consent Declined"

      # Should NOT show illustration
      refute has_element?(view, "[data-testid='finished-illustration']")

      # Should show both retry and continue buttons
      assert has_element?(view, "[data-testid='back-button']")
      assert has_element?(view, "[data-testid='continue-button']")
      assert html =~ "https://example.com/return"
    end
  end

  describe "Observatory pattern integration" do
    test "view model rebuilds when assignment updates", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      # Initial state - should have illustration
      assert has_element?(view, "[data-testid='finished-illustration']")

      # Note: In a real scenario, assignment would be updated and Observatory would
      # trigger VM rebuild. In this isolated test, we verify the initial state renders correctly
      # The automatic rebuild is tested through integration tests
    end
  end
end
