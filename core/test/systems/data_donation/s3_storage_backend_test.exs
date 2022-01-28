defmodule Systems.DataDonation.S3StorageBackendTest do
  use Core.DataCase, async: true

  alias Systems.DataDonation.S3StorageBackend
  alias Systems.DataDonation.ToolModel

  describe "path/1" do
    test "generates a unique path based on the tool" do
      assert S3StorageBackend.path(%ToolModel{id: 2}) =~ "2/"
    end
  end
end
