defmodule Frameworks.Pixel.ImageCatalogPicker.Test.View do
  use Phoenix.LiveView, layout: {Fabric.TestLayouts, :live}
  use Fabric.LiveView

  alias Frameworks.Pixel.ImageCatalogPicker

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> Fabric.new_fabric()
      |> compose_child(:image_picker)
    }
  end

  @impl true
  def compose(:image_picker, _) do
    %{
      module: ImageCatalogPicker,
      params: %{
        viewport: nil,
        breakpoint: nil,
        static_path: &CoreWeb.Endpoint.static_path/1,
        image_catalog: Core.ImageCatalog.Local,
        initial_query: "",
        state: nil
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.child name={:image_picker} fabric={@fabric} />
    </div>
    """
  end

  @impl true
  def handle_event("set_image_id", %{"image_id" => image_id}, socket) do
    {:noreply, socket |> assign(:image_id, image_id)}
  end
end

defmodule Frameworks.Pixel.ImageCatalogPicker.Test do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  setup do
    conn = Phoenix.ConnTest.build_conn(:get, "/", nil)

    {:ok, view, html} =
      live_isolated(conn, Frameworks.Pixel.ImageCatalogPicker.Test.View,
        connect_params: %{testing: 1124}
      )

    {:ok, [view: view, html: html]}
  end

  describe "image search" do
    test "searching for non-existent images shows no results", %{view: view} do
      assert view
             |> element("form")
             |> render_submit(%{q: "somethingwhichdoesnotexist"}) =~ "No images found"
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
