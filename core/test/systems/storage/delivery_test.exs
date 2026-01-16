defmodule Systems.Storage.DeliveryTest do
  use Core.DataCase, async: false
  use Oban.Testing, repo: Core.Repo

  import Mox
  import Frameworks.Signal.TestHelper

  alias Systems.Storage.Delivery
  alias Systems.Storage.JobDataModel
  alias Systems.Storage.BuiltIn.Backend
  alias Systems.Storage.BuiltIn.MockSpecial

  # Force module load to register atom in atom table
  require Backend

  setup :verify_on_exit!

  setup do
    # Isolate signals to prevent side effects during testing
    isolate_signals()

    # Configure mock backend
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)
    Application.put_env(:core, Systems.Storage.BuiltIn, special: MockSpecial)

    on_exit(fn ->
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_config)
    end)

    :ok
  end

  describe "perform/1 with blob_id" do
    test "fetches blob, delivers, and marks as finished on success" do
      # Create blob
      data = "test donation data"

      {:ok, blob} =
        JobDataModel.prepare(data)
        |> Repo.insert()

      # Mock successful delivery
      expect(MockSpecial, :store, fn _folder, _filename, received_data ->
        assert received_data == data
        :ok
      end)

      # Create job args with blob_id
      args = %{
        "blob_id" => blob.id,
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "meta_data" => %{"identifier" => [[:participant, 1]]}
      }

      # Perform job
      assert :ok = perform_job(Delivery, args)

      # Job data should be marked as finished (not deleted)
      updated_blob = Repo.get(JobDataModel, blob.id)
      assert updated_blob != nil
      assert updated_blob.status == :finished
    end

    test "keeps blob pending on delivery failure for retry" do
      # Create blob
      data = "test data for retry"

      {:ok, blob} =
        JobDataModel.prepare(data)
        |> Repo.insert()

      # Mock failed delivery
      expect(MockSpecial, :store, fn _folder, _filename, _data ->
        {:error, "S3 connection failed"}
      end)

      args = %{
        "blob_id" => blob.id,
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "meta_data" => %{"identifier" => []}
      }

      # Job should return error
      assert {:error, _} = perform_job(Delivery, args)

      # Blob should still exist and remain pending for retry
      updated_blob = Repo.get(JobDataModel, blob.id)
      assert updated_blob != nil
      assert updated_blob.status == :pending
    end

    test "discards job if blob not found" do
      # Non-existent blob ID
      args = %{
        "blob_id" => 999_999_999,
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "meta_data" => %{"identifier" => []}
      }

      # Job should be discarded (not retried)
      assert {:discard, reason} = perform_job(Delivery, args)
      assert reason =~ "not found"
    end
  end

  describe "perform/1 with legacy data field" do
    test "supports legacy jobs with data directly in args" do
      data = "legacy donation data"

      # Mock successful delivery
      expect(MockSpecial, :store, fn _folder, _filename, received_data ->
        assert received_data == data
        :ok
      end)

      # Legacy job args with data field instead of blob_id
      args = %{
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "data" => data,
        "meta_data" => %{"identifier" => [[:participant, 1]]}
      }

      # Should work with legacy format
      assert :ok = perform_job(Delivery, args)
    end
  end
end
