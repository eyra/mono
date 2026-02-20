defmodule Systems.Account.ProfileViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  setup do
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "rendering" do
    test "renders profile view with title and form", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: user.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, view, html} = live_isolated(conn, Account.ProfileView, session: session)

      # Should render title
      assert html =~ "My profile"

      # Should render form elements
      assert view |> has_element?("[data-testid='profile-view']")

      # Should render name inputs
      assert html =~ "fullname"
      assert html =~ "displayname"

      # Should render email (non-editable)
      assert html =~ user.email
    end

    test "renders signout button", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: user.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Account.ProfileView, session: session)

      # Should render signout button
      assert html =~ "Sign out" or html =~ "Uitloggen"
    end
  end

  describe "form interactions" do
    test "saves fullname on change", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: user.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Account.ProfileView, session: session)

      # Submit name change
      view |> render_change("save", %{"user_profile_edit_model" => %{"fullname" => "New Name"}})

      # Verify it was saved
      profile = Account.Public.get_profile(user) |> Repo.reload!()
      assert profile.fullname == "New Name"
    end

    test "saves displayname on change", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: user.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Account.ProfileView, session: session)

      # Submit displayname change
      view
      |> render_change("save", %{"user_profile_edit_model" => %{"displayname" => "NewDisplay"}})

      # Verify it was saved - displayname is stored on the user, not the profile
      updated_user = Account.Public.get_user!(user.id)
      assert updated_user.displayname == "NewDisplay"
    end
  end

  describe "creator-specific fields" do
    test "shows title field for creator users", %{conn: conn} do
      creator = Factories.insert!(:member, %{creator: true})

      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: creator.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Account.ProfileView, session: session)

      # Should render title input for creators
      assert html =~ "title"
    end

    test "hides title field for non-creator users", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/profile")

      live_context =
        LiveContext.new(%{
          user_id: user.id,
          show_signout_button: true,
          show_email: true
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Account.ProfileView, session: session)

      # Should NOT render title input for non-creators
      # Check that Professional title label is not present
      refute html =~ "Professional title" or html =~ "Professionele titel"
    end
  end
end
