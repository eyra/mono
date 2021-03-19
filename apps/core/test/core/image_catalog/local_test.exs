defmodule Core.ImageCatalog.Local.Test do
  use ExUnit.Case, async: true
  alias Core.ImageCatalog.Local

  describe "search/1" do
    test "empty query returns nothing" do
      assert Local.search("") == []
    end

    test "empty results with no matching query" do
      assert Local.search("something-which-does-not-exist") == []
    end

    test "returns when part of the file name matches" do
      assert Local.search("magenta") == ["cyan_magenta"]
    end
  end

  describe "search_info/1" do
    test "returns image info" do
      assert Local.search_info("magenta", []) == [
               %{
                 id: "cyan_magenta",
                 srcset: "/image-catalog/cyan_magenta_1920x1080.jpg 1x",
                 url: "/image-catalog/cyan_magenta_1920x1080.jpg"
               }
             ]
    end
  end

  describe "info/2" do
    test "nil with id that does not exist" do
      assert is_nil(Local.info("something-which-does-not-exist", []))
    end

    test "returns info for existing id" do
      assert Local.info("cyan_magenta", []) == %{
               id: "cyan_magenta",
               srcset: "/image-catalog/cyan_magenta_1920x1080.jpg 1x",
               url: "/image-catalog/cyan_magenta_1920x1080.jpg"
             }
    end
  end
end
