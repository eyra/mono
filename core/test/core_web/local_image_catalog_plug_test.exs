defmodule CoreWeb.LocalImageCatalogPlug.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  alias CoreWeb.LocalImageCatalogPlug

  def call(conn) do
    LocalImageCatalogPlug.call(conn, [])
  end

  describe "call/1" do
    test "returns not found for unknown image" do
      assert call(conn(:get, "/image-catalog/not-found.jpg")).status == 404
    end

    test "returns image data" do
      assert call(conn(:get, "/image-catalog/cyan_magenta_1920x1080.jpg")).status == 200
    end
  end
end
