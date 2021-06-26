defmodule CoreWeb.FileUploader.Test do
  use ExUnit.Case, async: true
  alias CoreWeb.FileUploader

  describe "get_static_path/1" do
    test "throws error for paths that would be outside root" do
      assert catch_throw(FileUploader.get_static_path("../test.jpg"))
    end

    test "return path for valid filename" do
      assert FileUploader.get_static_path("f94eae50-5bad-4c50-82ad-f0cf067394c1.jpg") ==
               "priv/static/uploads/f94eae50-5bad-4c50-82ad-f0cf067394c1.jpg"
    end
  end
end
