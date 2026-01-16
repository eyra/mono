defmodule Systems.Storage.PendingBlobModelTest do
  use Core.DataCase, async: true

  alias Systems.Storage.PendingBlobModel

  describe "prepare/1" do
    test "creates valid changeset with binary data" do
      data = "test binary data"
      changeset = PendingBlobModel.prepare(data)

      assert changeset.valid?
      assert changeset.changes.data == data
    end

    test "creates valid changeset with large binary data" do
      # Simulate a 1MB file
      data = :crypto.strong_rand_bytes(1_000_000)
      changeset = PendingBlobModel.prepare(data)

      assert changeset.valid?
      assert byte_size(changeset.changes.data) == 1_000_000
    end

    test "creates valid changeset with empty binary" do
      changeset = PendingBlobModel.prepare("")

      # Empty binary should fail validation (required field)
      refute changeset.valid?
    end
  end

  describe "database operations" do
    test "inserts and retrieves blob" do
      data = "test data for storage"

      {:ok, blob} =
        PendingBlobModel.prepare(data)
        |> Repo.insert()

      assert blob.id != nil
      assert blob.data == data
      assert blob.inserted_at != nil
    end

    test "deletes blob" do
      data = "data to delete"

      {:ok, blob} =
        PendingBlobModel.prepare(data)
        |> Repo.insert()

      assert {:ok, _} = Repo.delete(blob)
      assert Repo.get(PendingBlobModel, blob.id) == nil
    end

    test "stores binary data without JSON encoding overhead" do
      # Create binary data that would be problematic in JSON
      data = <<0, 1, 2, 255, 254, 253>>

      {:ok, blob} =
        PendingBlobModel.prepare(data)
        |> Repo.insert()

      retrieved = Repo.get(PendingBlobModel, blob.id)
      assert retrieved.data == data
    end
  end
end
