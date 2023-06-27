defmodule CoreWeb.UI.ImageCatalogPicker.Test.View do
  use Phoenix.LiveView
  alias CoreWeb.UI.ImageCatalogPicker

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={ImageCatalogPicker}
        id="picker"
        image_catalog={Core.ImageCatalog.Local}
        static_path={&CoreWeb.Endpoint.static_path/1}
      />
    </div>
    """
  end

  @impl true
  def handle_event("set_image_id", %{"image_id" => image_id}, socket) do
    {:noreply, socket |> assign(:image_id, image_id)}
  end
end

defmodule CoreWeb.UI.ImageCatalogPicker.Test do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  setup do
    conn = Phoenix.ConnTest.build_conn(:get, "/", nil)

    {:ok, view, html} =
      live_isolated(conn, CoreWeb.UI.ImageCatalogPicker.Test.View,
        connect_params: %{testing: 1124}
      )

    {:ok, [view: view, html: html]}
  end

  describe "image search" do
    test "searching for non-existent images shows no results", %{view: view} do
      assert view
             |> element("form")
             |> render_submit(%{q: "somethingwhichdoesnotexist"}) =~ "Geen afbeeldingen gevonden"
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
        |> element("div[id=clickable-area-0]")
        |> render_click()

      assert html =~ "cyan"
      assert html =~ "<img"
    end
  end
end
