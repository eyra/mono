defmodule CoreWeb.Live.Hook.TimezoneTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias CoreWeb.Live.Hook.Timezone

  defmodule TimezoneTestView do
    use Phoenix.LiveView

    on_mount({Timezone, __MODULE__})

    @impl true
    def mount(:not_mounted_at_router, _session, socket) do
      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div data-testid="timezone-display">{@timezone}</div>
      """
    end
  end

  describe "timezone hook" do
    test "extracts timezone from connect params", %{conn: conn} do
      {:ok, view, html} =
        conn
        |> Map.put(:request_path, "/test")
        |> put_connect_params(%{"timezone" => "America/New_York"})
        |> live_isolated(TimezoneTestView)

      assert html =~ "America/New_York"
      assert has_element?(view, "[data-testid='timezone-display']", "America/New_York")
    end

    test "defaults to Europe/Amsterdam when no timezone provided", %{conn: conn} do
      {:ok, view, html} =
        conn
        |> Map.put(:request_path, "/test")
        |> put_connect_params(%{})
        |> live_isolated(TimezoneTestView)

      assert html =~ "Europe/Amsterdam"
      assert has_element?(view, "[data-testid='timezone-display']", "Europe/Amsterdam")
    end

    test "uses different timezone from connect params", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "/test")
        |> put_connect_params(%{"timezone" => "Asia/Tokyo"})
        |> live_isolated(TimezoneTestView)

      assert has_element?(view, "[data-testid='timezone-display']", "Asia/Tokyo")
    end
  end
end
