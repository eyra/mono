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

  describe "Selector component" do
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
