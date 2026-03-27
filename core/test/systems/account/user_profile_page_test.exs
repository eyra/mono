defmodule Systems.Account.UserProfilePageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Pool

  setup %{conn: conn} do
    isolate_signals()

    user =
      Factories.insert!(:member, %{
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    {:ok, conn: conn, user: user} = login(user, %{conn: conn})

    %{conn: conn, user: user}
  end

  describe "rendering" do
    test "renders user profile page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/profile")

      # Should render the page with profile content
      assert html =~ "profile" or html =~ "Profile"
    end

    test "renders profile tab by default", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/profile")

      # Should render the profile view
      assert view |> has_element?("[data-testid='profile-view']")
    end

    test "renders tabbar", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/profile")

      # Should have a tab bar
      assert html =~ "user_profile"
    end
  end

  describe "tab navigation" do
    test "can navigate to profile tab via URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/profile/profile")

      assert view |> has_element?("[data-testid='profile-view']")
    end
  end

  describe "PANL participant" do
    setup %{conn: conn} do
      user =
        Factories.insert!(:member, %{
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      {:ok, conn: logged_in_conn, user: _user} = login(user, %{conn: conn})

      %{conn: logged_in_conn, panl_user: user}
    end

    test "shows features tab for PANL participant", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/profile")

      # Should have both profile and features tabs
      assert html =~ "profile" or html =~ "Profile"
      assert html =~ "features" or html =~ "Features" or html =~ "Kenmerken"
    end

    test "can navigate to features tab via URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/profile/features")

      assert view |> has_element?("[data-testid='features-view']")
    end
  end
end
