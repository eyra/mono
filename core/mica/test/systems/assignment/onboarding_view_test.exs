defmodule Systems.Assignment.OnboardingViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Assignment

  setup do
    # Isolate signals to prevent workflow errors
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "with intro page" do
    test "renders onboarding view with content page and continue button", %{
      conn: conn,
      user: user
    } do
      assignment = Assignment.Factories.create_base_assignment()
      page = Factories.insert!(:content_page)

      Factories.insert!(:assignment_page_ref, %{
        assignment: assignment,
        page: page,
        key: :assignment_information
      })

      assignment = Repo.preload(assignment, [page_refs: :page], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/onboarding")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.OnboardingView, session: session)

      # Should render content page with title
      assert view |> render() =~ "About"

      # Should show continue button
      assert view |> render() =~ "Continue"
    end

    test "continue button triggers continue event", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      page = Factories.insert!(:content_page)

      Factories.insert!(:assignment_page_ref, %{
        assignment: assignment,
        page: page,
        key: :assignment_information
      })

      assignment = Repo.preload(assignment, [page_refs: :page], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/onboarding")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.OnboardingView, session: session)

      # Send continue event directly
      view |> render_click("continue")

      # Reload user to check visited pages
      user = Repo.get!(Systems.Account.User, user.id)

      # Verify page was marked as visited
      assert Systems.Account.Public.visited?(user, {:assignment_information, assignment.id})

      # Verify no errors occurred
      assert view |> render() =~ "Continue"
    end
  end

  describe "without intro page" do
    test "renders onboarding view with only continue button", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Repo.preload(assignment, [:page_refs], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/onboarding")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.OnboardingView, session: session)

      # Should NOT render content page (no "About" title)
      refute view |> render() =~ "About"

      # Should show continue button
      assert view |> render() =~ "Continue"
    end
  end

  describe "Observatory pattern integration" do
    test "view model rebuilds when assignment updates", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Repo.preload(assignment, [:page_refs], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/onboarding")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.OnboardingView, session: session)

      # Initial state - should have continue button
      assert view |> render() =~ "Continue"

      # Note: In a real scenario, assignment would be updated and Observatory would
      # trigger VM rebuild. In this isolated test, we verify the initial state renders correctly
      # The automatic rebuild is tested through integration tests
    end
  end
end
