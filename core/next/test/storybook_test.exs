defmodule Next.StorybookTest do
  use CoreWeb.ConnCase, async: false

  setup do
    features = Application.fetch_env!(:core, :features)
    Application.put_env(:core, :features, Keyword.put(features, :storybook, true))
    on_exit(fn -> Application.put_env(:core, :features, features) end)
  end

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
