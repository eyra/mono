defmodule Core.DataUploader.Test do
  use Core.DataCase, async: true
  alias Core.Factories
  alias Core.DataUploader

  describe "store_results/2" do
    setup do
      {:ok, client_script: Factories.insert!(:client_script)}
    end

    test "create a new record with the given data", %{client_script: client_script} do
      data = DataUploader.store_results(client_script, "some data")
      assert data.client_script_id == client_script.id
      assert data.data == "some data"
    end
  end
end
