defmodule Systems.Manual.Builder.PageFormTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Manual

  defmodule PageFormView do
    use Phoenix.LiveView

    def mount(_params, %{"page" => page}, socket) do
      fabric = %Fabric.Model{parent: nil, self: %Fabric.LiveView.RefModel{pid: self()}}
      {:ok, assign(socket, page: page, fabric: fabric)}
    end

    def render(assigns) do
      ~H"""
      <.live_component module={Manual.Builder.PageForm} id="page" page={@page} fabric={@fabric} />
      """
    end

    def handle_info(_message, socket), do: {:noreply, socket}
  end

  test "ignores an image sent with the title form", %{conn: conn} do
    %{chapters: [%{pages: [page]}]} = Manual.Factories.create_manual()

    {:ok, view, _html} =
      conn
      |> Map.put(:request_path, "/manual/page_form")
      |> live_isolated(PageFormView, session: %{"page" => page})

    view
    |> element("#page_title_form")
    |> render_change(%{
      "page_model" => %{"title" => "New title", "image" => "https://example.com/x.png"}
    })

    assert %{title: "New title", image: "Page image"} = Repo.get!(Manual.PageModel, page.id)
  end
end
