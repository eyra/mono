defmodule CoreWeb.ImageCatalogPicker.Test.View do
  use Surface.LiveView
  alias CoreWeb.ImageCatalogPicker

  data(image_id, :string, default: nil)

  def render(assigns) do
    ~H"""
    <div>
    <ImageCatalogPicker id="picker" image_catalog={{Core.ImageCatalog.Local}} />
    </div>
    """
  end

  def handle_event("set_image_id", %{"image_id" => image_id}, socket) do
    {:noreply, socket |> assign(:image_id, image_id)}
  end
end

defmodule CoreWeb.ImageCatalogPicker.Test do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest
  alias CoreWeb.ImageCatalogPicker

  setup %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, ImageCatalogPicker.Test.View, connect_params: %{testing: 1124})

    {:ok, [view: view, html: html]}
  end

  describe "image search" do
    test "searching for non-existent images shows no results", %{view: view} do
      assert view
             |> element("form")
             |> render_submit(%{q: "somethingwhichdoesnotexist"}) =~ "No results"
    end

    test "searching existing images shows results", %{view: view} do
      html =
        view
        |> element("form")
        |> render_submit(%{q: "magenta"})

      assert html =~ "cyan"
      assert html =~ "<img"
    end

    test "selecting an image updates picks it", %{view: view} do
      view
      |> element("form")
      |> render_submit(%{q: "magenta"})

      html =
        view
        |> element(".image")
        |> render_click()

      assert html =~ "cyan"
      assert html =~ "<img"
    end
  end
end
