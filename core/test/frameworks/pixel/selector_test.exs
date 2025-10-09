defmodule Frameworks.Pixel.SelectorTest.View do
  use Fabric.LiveView, CoreWeb.Layouts
  alias Frameworks.Pixel.Selector

  @impl true
  def mount(_params, session, socket) do
    items = session["items"] || []
    type = session["type"] || :radio
    optional? = Map.get(session, "optional?", true)
    raw? = Map.get(session, "raw?", false)

    self_ref = %Fabric.LiveView.RefModel{pid: self()}
    fabric = %Fabric.Model{parent: nil, self: self_ref, children: nil}

    {
      :ok,
      socket
      |> assign(fabric: fabric)
      |> assign(:active_item_id, nil)
      |> assign(:active_item_ids, [])
      |> assign(:items, items)
      |> assign(:type, type)
      |> assign(:optional?, optional?)
      |> assign(:raw?, raw?)
      |> compose_child(:selector)
    }
  end

  @impl true
  def compose(:selector, %{items: items, type: type, optional?: optional?, raw?: raw?}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: type,
        optional?: optional?,
        raw?: raw?
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.child name={:selector} fabric={@fabric} />
    </div>
    """
  end

  @impl true
  def handle_event("active_item_id", %{active_item_id: id}, socket) do
    {:noreply, socket |> assign(:active_item_id, id)}
  end

  @impl true
  def handle_event("active_item_ids", %{active_item_ids: ids}, socket) do
    {:noreply, socket |> assign(:active_item_ids, ids)}
  end

  @impl true
  def handle_event(_name, _payload, socket) do
    {:noreply, socket}
  end
end

defmodule Frameworks.Pixel.SelectorTest do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.SelectorTest.View

  setup do
    conn = Phoenix.ConnTest.build_conn(:get, "/", nil)
    {:ok, [conn: conn]}
  end

  describe "Selector component rendering" do
    test "renders radio selector correctly", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false},
        %{id: :option3, value: "Option 3", active: false}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :radio, "optional?" => false}
        )

      assert html =~ "Option 1"
      assert html =~ "Option 2"
      assert html =~ "Option 3"
      assert html =~ "selector-icon-active"
      assert html =~ "selector-icon-inactive"
    end

    test "renders checkbox selector correctly", %{conn: conn} do
      items = [
        %{id: :check1, value: "Check 1", active: true},
        %{id: :check2, value: "Check 2", active: false},
        %{id: :check3, value: "Check 3", active: true}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View, session: %{"items" => items, "type" => :checkbox})

      assert html =~ "Check 1"
      assert html =~ "Check 2"
      assert html =~ "Check 3"
    end

    test "renders segmented selector correctly", %{conn: conn} do
      items = [
        %{id: :seg1, value: "First", active: true},
        %{id: :seg2, value: "Second", active: false},
        %{id: :seg3, value: "Third", active: false}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :segmented, "optional?" => false}
        )

      assert html =~ "First"
      assert html =~ "Second"
      assert html =~ "Third"
      assert html =~ "data-selector-segment"
    end

    test "handles selector toggle events", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false}
      ]

      {:ok, view, _html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :radio, "optional?" => false}
        )

      view
      |> element("[data-selector-item='option2']")
      |> render_click()

      html = render(view)
      assert html =~ "Option 2"
    end

    test "renders label selector correctly", %{conn: conn} do
      items = [
        %{id: :label1, value: "Tag 1", active: true},
        %{id: :label2, value: "Tag 2", active: false},
        %{id: :label3, value: "Tag 3", active: true}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View, session: %{"items" => items, "type" => :label})

      assert html =~ "Tag 1"
      assert html =~ "Tag 2"
      assert html =~ "Tag 3"
      assert html =~ "data-selector-segment"
    end

    test "handles optional vs required selection", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false}
      ]

      {:ok, view, _html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :radio, "optional?" => true}
        )

      view
      |> element("[data-selector-item='option1']")
      |> render_click()

      html = render(view)
      assert html =~ "Option 1"
      assert html =~ "Option 2"
    end
  end

  describe "Selector with HTML content" do
    test "renders radio selector with plain text (escapes HTML when raw? is false)", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "<a href='test.com'>Link</a> text", active: false}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View, session: %{"items" => items, "type" => :radio, "raw?" => false})

      assert html =~ "Option 1"
      assert html =~ "selector-icon-active"
      assert html =~ "selector-icon-inactive"

      assert html =~ "Link"
      assert html =~ "text"
      refute html =~ "<a href"
      refute html =~ "href=\"test.com\""
    end

    test "renders radio selector with embedded HTML links", %{conn: conn} do
      items = [
        %{
          id: :consent,
          value:
            "Accept <a href='https://example.com/privacy' target='_blank'>privacy policy</a>",
          active: false
        }
      ]

      {:ok, _view, html} =
        live_isolated(conn, View, session: %{"items" => items, "type" => :radio, "raw?" => true})

      assert html =~ "Accept"
      assert html =~ "privacy policy"
      assert html =~ "href=\"https://example.com/privacy\""
      assert html =~ "target=\"_blank\""
    end

    test "renders checkbox selector with plain text (escapes HTML when raw? is false)", %{
      conn: conn
    } do
      items = [
        %{id: :check1, value: "Check 1", active: true},
        %{id: :check2, value: "I agree <script>alert('xss')</script> to terms", active: false}
      ]

      {:ok, _view, html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :checkbox, "raw?" => false}
        )

      assert html =~ "Check 1"
      assert html =~ "I agree"
      assert html =~ "to terms"

      refute html =~ "<script>"
      refute html =~ "alert('xss')"
      refute html =~ "<a href"
    end

    test "renders checkbox selector with embedded HTML links", %{conn: conn} do
      items = [
        %{
          id: :consent,
          value: "I agree to the <a href='https://example.com/terms' target='_blank'>terms</a>",
          active: false
        }
      ]

      {:ok, _view, html} =
        live_isolated(conn, View,
          session: %{"items" => items, "type" => :checkbox, "raw?" => true}
        )

      assert html =~ "I agree to the"
      assert html =~ "terms"
      assert html =~ "href=\"https://example.com/terms\""
      assert html =~ "target=\"_blank\""
    end
  end
end
