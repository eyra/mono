defmodule Systems.BFF.PageControllerTest do
  use MicaWeb.ConnCase, async: true

  alias Systems.NextAction

  defmodule TodoAction do
    @behaviour Systems.NextAction.ViewModel

    @impl true
    def to_view_model(_count, %{"title" => title}) do
      %{
        title: title,
        description: "About #{title}",
        cta_label: "Open #{title}",
        cta_action: %{type: :redirect, to: "/todo/#{title}"}
      }
    end
  end

  defp create_todo(user, title, opts \\ []) do
    NextAction.Public.create_next_action(
      user,
      TodoAction,
      Keyword.merge([key: title, params: %{"title" => title}], opts)
    )
  end

  describe "signed in" do
    setup :login_as_member

    test "home shows the user's To-dos as cards, in priority order", %{conn: conn, user: user} do
      create_todo(user, "later")
      create_todo(user, "first", priority: :high)

      assert %{
               "blocks" => [
                 %{
                   "type" => "card",
                   "props" => %{
                     "title" => "first",
                     "body" => "About first",
                     "cta" => "Open first",
                     "to" => "/todo/first"
                   }
                 },
                 %{"type" => "card", "props" => %{"title" => "later"}}
               ]
             } = conn |> get("/bff/page/home") |> json_response(200)
    end

    test "a page the spec doesn't list is not found", %{conn: conn} do
      assert %{"error" => "Not found"} = conn |> get("/bff/page/settings") |> json_response(404)
    end
  end

  test "signed out gets 401, before the page is looked up", %{conn: conn} do
    for page <- ["home", "settings"] do
      assert %{"error" => "Not authenticated"} =
               conn |> get("/bff/page/#{page}") |> json_response(401)
    end
  end

  test "the SaaS serves exactly the spec's pages" do
    assert Mica.SaaS.bff_pages() |> Map.keys() |> Enum.sort() ==
             Systems.BFF.Blocks.pages() |> Enum.map(& &1.name) |> Enum.sort()
  end
end
