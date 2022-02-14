defmodule Systems.DataDonation.S3StorageBackendTest do
  use Core.DataCase, async: true

  alias Systems.DataDonation.S3StorageBackend
  alias Systems.DataDonation.ToolModel

  describe "path/1" do
    test "generates a unique path" do
      assert S3StorageBackend.path() != S3StorageBackend.path()
    end
  end
end
