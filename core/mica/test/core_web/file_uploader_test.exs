defmodule CoreWeb.FileUploader.Test do
  use ExUnit.Case, async: true
  alias CoreWeb.FileUploader

  describe "get_upload_path/1" do
    test "throws error for files that would be outside root" do
      assert catch_throw(FileUploader.get_upload_path("../test.jpg"))
    end

    test "throws error for paths that would be outside root" do
      assert catch_throw(FileUploader.get_upload_path("../test"))
    end

    test "return path for valid filename" do
      assert FileUploader.get_upload_path("f94eae50-5bad-4c50-82ad-f0cf067394c1.jpg") ==
               "/tmp/f94eae50-5bad-4c50-82ad-f0cf067394c1.jpg"
    end
  end
end
