defmodule Systems.Storage.JobDataModelTest do
  use Core.DataCase, async: true

  alias Systems.Storage.JobDataModel

  describe "prepare/1" do
    test "creates valid changeset with binary data" do
      data = "test binary data"
      changeset = JobDataModel.prepare(data)

      assert changeset.valid?
      assert changeset.changes.data == data
    end

    test "creates valid changeset with large binary data" do
      # Simulate a 1MB file
      data = :crypto.strong_rand_bytes(1_000_000)
      changeset = JobDataModel.prepare(data)

      assert changeset.valid?
      assert byte_size(changeset.changes.data) == 1_000_000
    end

    test "creates valid changeset with empty binary" do
      changeset = JobDataModel.prepare("")

      # Empty binary should fail validation (required field)
      refute changeset.valid?
    end

    test "defaults status to pending" do
      data = "test data"
      changeset = JobDataModel.prepare(data)

      # Status should not be in changes (uses default)
      refute Map.has_key?(changeset.changes, :status)
    end

    test "accepts optional user and meta_data" do
      data = "test data"
      meta_data = %{remote_ip: "127.0.0.1", identifier: [[:key, "test"]]}
      changeset = JobDataModel.prepare(data, nil, meta_data)

      assert changeset.valid?
      assert changeset.changes.meta_data == meta_data
    end

    test "meta_data defaults to nil" do
      data = "test data"
      changeset = JobDataModel.prepare(data)

      refute Map.has_key?(changeset.changes, :meta_data)
    end
  end

  describe "mark_finished/1" do
    test "creates changeset marking job data as finished" do
      {:ok, job_data} =
        JobDataModel.prepare("test data")
        |> Repo.insert()

      assert job_data.status == :pending

      changeset = JobDataModel.mark_finished(job_data)

      assert changeset.valid?
      assert changeset.changes.status == :finished
    end

    test "updates status in database" do
      {:ok, job_data} =
        JobDataModel.prepare("test data")
        |> Repo.insert()

      {:ok, updated} =
        JobDataModel.mark_finished(job_data)
        |> Repo.update()

      assert updated.status == :finished
    end
  end

  describe "database operations" do
    test "inserts and retrieves job data" do
      data = "test data for storage"

      {:ok, job_data} =
        JobDataModel.prepare(data)
        |> Repo.insert()

      assert job_data.id != nil
      assert job_data.data == data
      assert job_data.status == :pending
      assert job_data.inserted_at != nil
    end

    test "deletes job data" do
      data = "data to delete"

      {:ok, job_data} =
        JobDataModel.prepare(data)
        |> Repo.insert()

      assert {:ok, _} = Repo.delete(job_data)
      assert Repo.get(JobDataModel, job_data.id) == nil
    end

    test "stores binary data without JSON encoding overhead" do
      # Create binary data that would be problematic in JSON
      data = <<0, 1, 2, 255, 254, 253>>

      {:ok, job_data} =
        JobDataModel.prepare(data)
        |> Repo.insert()

      retrieved = Repo.get(JobDataModel, job_data.id)
      assert retrieved.data == data
    end
  end
end
