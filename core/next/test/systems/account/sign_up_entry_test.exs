defmodule Next.Systems.Account.SignUpEntryTest do
  @moduledoc """
  Where Next sends a signed-out person to sign up: the code page when
  sign-in codes (`:otp`) are on, the password sign-up page otherwise.
  """
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  import Phoenix.LiveViewTest

  describe "with sign-in codes on" do
    setup do
      set_feature_flag(:otp, true)
      :ok
    end

    test "Home's Sign up goes to the code page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "[data-testid='home-guest-view'] a[href='/user/auth/identify']")
      refute has_element?(view, "a[href='/user/signup/creator']")
    end

    test "the creator sign-up page sends to the code page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/user/auth/identify"}}} =
               live(conn, ~p"/user/signup/creator")
    end

    test "the participant sign-up page sends to the participant code page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/user/auth/identify/participant"}}} =
               live(conn, ~p"/user/signup/participant")
    end

    test "add_to_panl carries on as a return to the Panl join page", %{conn: conn} do
      set_feature_flag(:panl, true)

      assert {:error,
              {:redirect,
               %{to: "/user/auth/identify/participant?return_to=%2Fpool%2Fpanl%2Fjoin"}}} =
               live(conn, ~p"/user/signup/participant?post_signup_action=add_to_panl")
    end

    test "add_to_panl is dropped with Panl off", %{conn: conn} do
      set_feature_flag(:panl, false)

      assert {:error, {:redirect, %{to: "/user/auth/identify/participant"}}} =
               live(conn, ~p"/user/signup/participant?post_signup_action=add_to_panl")
    end

    test "join_pool carries on as a return to that pool's join page", %{conn: conn} do
      # The join page takes only a slug that is an existing atom, as `panl` is.
      slug = Atom.to_string(:sign_up_entry_pool)
      Factories.insert!(:pool, %{name: "Sign up entry pool", director: :citizen})

      assert {:error,
              {:redirect,
               %{
                 to:
                   "/user/auth/identify/participant?return_to=%2Fpool%2Fsign_up_entry_pool%2Fjoin"
               }}} =
               live(
                 conn,
                 ~p"/user/signup/participant?post_signup_action=join_pool:#{slug}"
               )
    end

    test "join_pool with an unknown pool is dropped", %{conn: conn} do
      # One slug is not an atom at all; the other is an atom that names no pool.
      for slug <- ["sign_up_entry_unknown_pool", Atom.to_string(:sign_up_entry_no_pool)] do
        assert {:error, {:redirect, %{to: "/user/auth/identify/participant"}}} =
                 live(conn, ~p"/user/signup/participant?post_signup_action=join_pool:#{slug}")
      end
    end

    test "the sign-up page sends to the code page with password sign-in off", %{conn: conn} do
      set_feature_flag(:password_sign_in, false)

      assert {:error, {:redirect, %{to: "/user/auth/identify"}}} =
               live(conn, ~p"/user/signup/creator")
    end
  end

  describe "with sign-in codes off" do
    setup do
      set_feature_flag(:otp, false)
      :ok
    end

    test "Home's Sign up goes to the password sign-up page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(
               view,
               "[data-testid='home-guest-view'] a[href='/user/signup/creator']"
             )
    end

    test "the sign-up page stays", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/signup/creator")

      assert has_element?(view, "[data-testid='signup-page']")
    end
  end
end
