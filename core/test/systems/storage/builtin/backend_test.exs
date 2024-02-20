defmodule Systems.Storage.BuiltIn.BackendTest do
  use ExUnit.Case, async: true

  import Mox

  alias Systems.Storage.BuiltIn.Backend
  alias Systems.Storage.BuiltIn.MockSpecial

  setup :verify_on_exit!

  setup do
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)

    Application.put_env(:core, Systems.Storage.BuiltIn, special: MockSpecial)

    on_exit(fn ->
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_config)
    end)

    :ok
  end

  describe "store/4" do
    test "unknown folder" do
      assert {:error, :endpoint_key_missing} = Backend.store(%{}, %{}, "data", %{})
    end

    test "unknown participant" do
      expect(MockSpecial, :store, fn _, identifier, data ->
        assert ["participant=?", _unix_timestamp] = identifier
        assert "data" = data
        :ok
      end)

      assert :ok = Backend.store(%{"key" => "assignment=1"}, %{}, "data", %{})
    end

    test "folder + participant" do
      expect(MockSpecial, :store, fn folder, identifier, _data ->
        assert "assignment=1" = folder
        assert ["participant=1", _unix_timestamp] = identifier
        :ok
      end)

      assert :ok = Backend.store(%{"key" => "assignment=1"}, %{"participant" => 1}, "data", %{})
    end

    test "folder + participant + meta key" do
      expect(MockSpecial, :store, fn folder, identifier, _data ->
        assert "assignment=1" = folder
        assert ["participant=1", "session=1"] = identifier
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, %{"participant" => 1}, "data", %{
                 "key" => "session=1"
               })
    end

    test "folder + participant + meta key + group" do
      expect(MockSpecial, :store, fn folder, identifier, _data ->
        assert "assignment=1" = folder
        assert ["participant=1", "source=apple", "session=1"] = identifier
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, %{"participant" => 1}, "data", %{
                 "key" => "session=1",
                 "group" => "apple"
               })
    end

    test "folder + participant + meta key + group=nil" do
      expect(MockSpecial, :store, fn folder, identifier, _data ->
        assert "assignment=1" = folder
        assert ["participant=1", "session=1"] = identifier
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, %{"participant" => 1}, "data", %{
                 "key" => "session=1",
                 "group" => nil
               })
    end
  end
end
