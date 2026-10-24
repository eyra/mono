defmodule Next.StorybookTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  setup do
    set_feature_flag(:storybook, true)
    :ok
  end

  describe "access" do
    test "is not found while the feature is off", %{conn: conn} do
      set_feature_flag(:storybook, false)
      {:ok, conn: conn, user: _} = login_as_admin(%{conn: conn})

      assert conn |> get("/admin/storybook-next") |> response(404)
    end

    test "is denied to visitors", %{conn: conn} do
      assert conn |> get("/admin/storybook-next") |> redirected_to() == "/access_denied"
    end

    test "is denied to members", %{conn: conn} do
      {:ok, ctx} = login_as_member(%{conn: conn})

      assert ctx[:conn] |> get("/admin/storybook-next") |> redirected_to() == "/access_denied"
    end
  end

  describe "stories" do
    setup :login_as_admin

    test "every story renders", %{conn: conn} do
      for %{path: path} <- Next.Storybook.leaves() do
        try do
          conn |> get("/admin/storybook-next" <> path) |> html_response(200)
        rescue
          error -> flunk("story #{path} does not render: #{Exception.message(error)}")
        end
      end
    end
  end
end
