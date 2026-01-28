defmodule Systems.Storage.DeliveryTest do
  use Core.DataCase, async: false
  use Oban.Testing, repo: Core.Repo

  import Mox
  import Frameworks.Signal.TestHelper

  alias Systems.Storage.Delivery
  alias Systems.Feldspar.DataDonationFolder
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

    # Clean up test data donation directory
    data_donation_path = Application.get_env(:core, :feldspar_data_donation)[:path]
    File.rm_rf(data_donation_path)

    on_exit(fn ->
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_config)
      File.rm_rf(data_donation_path)
    end)

    :ok
  end

  describe "perform/1 with file_id" do
    test "fetches file and delivers on success" do
      # Create data donation file with explicit file_id (matching S3 filename format)
      data = "test donation data"
      file_id = "participant=1_key=test.json"
      {:ok, %{id: ^file_id}} = DataDonationFolder.store(data, file_id)

      # Verify file exists
      assert {:ok, ^data} = DataDonationFolder.read(file_id)

      # Mock successful delivery
      expect(MockSpecial, :store, fn _folder, _filename, received_data ->
        assert received_data == data
        :ok
      end)

      # Create job args with file_id
      args = %{
        "file_id" => file_id,
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "meta_data" => %{"identifier" => [[:participant, 1]]}
      }

      # Perform job
      assert :ok = perform_job(Delivery, args)

      # File remains for cleanup worker to handle later
      assert {:ok, ^data} = DataDonationFolder.read(file_id)
    end

    test "returns error on delivery failure" do
      # Create data donation file
      data = "test data for retry"
      file_id = "participant=2_key=retry.json"
      {:ok, %{id: ^file_id}} = DataDonationFolder.store(data, file_id)

      # Mock failed delivery
      expect(MockSpecial, :store, fn _folder, _filename, _data ->
        {:error, "S3 connection failed"}
      end)

      args = %{
        "file_id" => file_id,
        "endpoint_id" => 1,
        "backend" => "Elixir.Systems.Storage.BuiltIn.Backend",
        "special" => %{"key" => "assignment=1"},
        "meta_data" => %{"identifier" => []}
      }

      # Job should return error for retry
      assert {:error, _} = perform_job(Delivery, args)
    end

    test "discards job if file not found" do
      # Non-existent file ID
      args = %{
        "file_id" => "nonexistent_file_id",
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

      # Legacy job args with data field instead of file_id
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
