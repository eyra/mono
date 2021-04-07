defmodule Core.ImageCatalog.Local.Test do
  use ExUnit.Case, async: true
  alias Core.ImageCatalog.Local

  describe "search/1" do
    test "empty query returns nothing" do
      assert Local.search("", 1, 10) == %{
               images: [],
               meta: %{begin: 0, end: 10, image_count: 0, page: 1, page_count: 0, page_size: 10}
             }
    end

    test "empty results with no matching query" do
      assert Local.search("something-which-does-not-exist", 1, 10) == %{
               images: [],
               meta: %{begin: 0, end: 10, image_count: 0, page: 1, page_count: 1, page_size: 10}
             }
    end

    test "returns when part of the file name matches" do
      assert Local.search("magenta", 1, 10) == %{
               images: ["cyan_magenta"],
               meta: %{begin: 0, end: 10, image_count: 1, page: 1, page_count: 1, page_size: 10}
             }
    end
  end

  describe "search_info/1" do
    test "returns image info" do
      assert Local.search_info("magenta", 1, 10, []) == %{
               images: [
                 %{
                   id: "cyan_magenta",
                   srcset: "/image-catalog/cyan_magenta_1920x1080.jpg 1x",
                   url: "/image-catalog/cyan_magenta_1920x1080.jpg"
                 }
               ],
               meta: %{begin: 0, end: 10, image_count: 1, page: 1, page_count: 1, page_size: 10}
             }
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
