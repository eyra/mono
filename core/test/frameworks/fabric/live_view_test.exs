defmodule Fabric.LiveViewTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "launching live view mock", %{conn: conn} do
    {:ok, _view, html} =
      conn
      |> Map.put(:request_path, "")
      |> put_connect_params(%{"param" => "value"})
      |> live_isolated(Fabric.LiveViewMock)

    assert html =~ "Child A"
    assert html =~ "Child B"
  end
end
