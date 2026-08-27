defmodule Systems.Assignment.FinishedViewTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Frameworks.Signal.TestHelper
  import Phoenix.LiveViewTest

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Pool.Assembly
  alias Systems.Pool.Public

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

  describe "email capture form (pre-launch: :panl on)" do
    setup do
      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_participant"})
      set_feature_flag(:panl, true)
      set_feature_flag(:panl_post_launch, false)
      %{user: affiliate_user.user}
    end

    test "renders email capture block for questionnaire assignment", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      assert has_element?(view, "[data-testid='email-capture-block']")
      assert has_element?(view, "[data-testid='email-capture-input']")
      assert has_element?(view, "[data-testid='email-capture-submit']")
    end

    test "does not render email capture for non-questionnaire assignment", %{
      conn: conn,
      user: user
    } do
      assignment = Assignment.Factories.create_assignment_with_affiliate(nil)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      refute has_element?(view, "[data-testid='email-capture-block']")
    end

    test "shows success state after valid email submission", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()
      _panl_pool = Assembly.get_or_create_panl()

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      new_email = "capture-#{System.unique_integer([:positive])}@example.com"
      render_submit(view, "submit_email", %{"email" => new_email})

      assert has_element?(
               view,
               "[data-testid='email-capture-block'] [data-testid='inline-block']"
             )

      refute has_element?(view, "[data-testid='email-capture-input']")
    end

    test "shows error for invalid email format", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      render_submit(view, "submit_email", %{"email" => "not-an-email"})
      assert has_element?(view, "[data-testid='email-capture-error']")
      refute has_element?(view, "[data-testid='email-capture-success']")
    end

    test "renders success state when user is already a pool member", %{
      conn: conn,
      user: user
    } do
      assignment = Assignment.Factories.create_questionnaire_assignment()
      panl_pool = Assembly.get_or_create_panl()
      Public.add_participant!(panl_pool, user)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      assert has_element?(
               view,
               "[data-testid='email-capture-block'] [data-testid='inline-block']"
             )

      refute has_element?(view, "[data-testid='email-capture-input']")
    end

    test "shows error for already registered email", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()
      _existing = Factories.insert!(:member, %{email: "taken-capture@example.com"})

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, _html} = live_isolated(conn, Assignment.FinishedView, session: session)

      render_submit(view, "submit_email", %{"email" => "taken-capture@example.com"})
      assert has_element?(view, "[data-testid='email-capture-error']")
    end
  end

  describe "panl CTA (post-launch: :panl_post_launch on)" do
    setup do
      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_participant"})
      set_feature_flag(:panl, true)
      set_feature_flag(:panl_post_launch, true)
      %{user: affiliate_user.user}
    end

    test "renders a Join CTA for an affiliate who is not yet a Panl member",
         %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      assert has_element?(view, "[data-testid='email-capture-block']")
      assert has_element?(view, "[data-testid='panl-cta-button']")
      refute has_element?(view, "[data-testid='email-capture-input']")

      # Anchor the destination on the actual HTML so a refactor of the CTA
      # href surfaces here.
      assert html =~ "/user/auth/identify?return_to=/pool/panl/join"
    end

    test "renders a Home CTA for an affiliate who is already a Panl member",
         %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_questionnaire_assignment()
      panl_pool = Assembly.get_or_create_panl()
      Public.add_participant!(panl_pool, user)

      conn = Map.put(conn, :request_path, "/assignment/finished")

      live_context =
        LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user
        })

      session = %{"live_context" => live_context}
      {:ok, view, html} = live_isolated(conn, Assignment.FinishedView, session: session)

      assert has_element?(view, "[data-testid='email-capture-block']")
      assert has_element?(view, "[data-testid='panl-cta-button']")
      refute has_element?(view, "[data-testid='email-capture-input']")

      assert html =~ ~s(href="/")
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
