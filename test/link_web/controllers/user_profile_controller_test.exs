defmodule LinkWeb.UserProfileControllerTest do
  use LinkWeb.ConnCase

  alias Link.Factories

  @update_attrs %{fullname: "Ada Lovelace", displayname: "Ada"}
  @invalid_attrs %{fullname: nil, displayname: nil}

  setup %{conn: conn} do
    user = Factories.get_or_create_user()
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user}
  end

  describe "edit a profile" do
    test "renders form for editing chosen study", %{conn: conn} do
      conn = get(conn, Routes.user_profile_path(conn, :edit))
      assert html_response(conn, 200)
    end
  end

  describe "update profile" do
    test "redirects when data is valid", %{conn: conn} do
      update_conn = put(conn, Routes.user_profile_path(conn, :update), profile: @update_attrs)

      assert redirected_to(update_conn) == Routes.user_profile_path(update_conn, :edit)

      conn = get(conn, Routes.user_profile_path(conn, :edit))
      assert html_response(conn, 200) =~ "Ada Lovelace"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, Routes.user_profile_path(conn, :update), profile: @invalid_attrs)
      assert html_response(conn, 200)
    end
  end
end
