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

  describe "filename/1" do
    test "empty identifier" do
      assert ".json" = Backend.filename(%{"identifier" => []})
    end

    test "single identifier" do
      assert "participant=1.json" = Backend.filename(%{"identifier" => [[:participant, 1]]})
    end

    test "multiple identifiers" do
      meta_data = %{"identifier" => [[:assignment, 1], [:participant, "abc"], [:source, "test"]]}
      assert "assignment=1_participant=abc_source=test.json" = Backend.filename(meta_data)
    end
  end

  describe "store/4" do
    test "unknown folder" do
      assert {:error, :endpoint_key_missing} = Backend.store(%{}, "data", %{})
    end

    test "unknown participant" do
      expect(MockSpecial, :store, fn folder, filename, data ->
        assert "assignment=1" = folder
        assert ".json" = filename
        assert "data" = data
        :ok
      end)

      assert :ok = Backend.store(%{"key" => "assignment=1"}, "data", %{"identifier" => []})
    end

    test "folder + participant" do
      expect(MockSpecial, :store, fn folder, filename, _data ->
        assert "assignment=1" = folder
        assert "participant=1.json" = filename
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, "data", %{
                 "identifier" => [[:participant, 1]]
               })
    end

    test "folder + participant + meta key" do
      expect(MockSpecial, :store, fn folder, filename, _data ->
        assert "assignment=1" = folder
        assert "participant=1_session=1.json" = filename
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, "data", %{
                 "identifier" => [[:participant, 1], [:session, 1]]
               })
    end

    test "folder + participant + meta key + source" do
      expect(MockSpecial, :store, fn folder, filename, _data ->
        assert "assignment=1" = folder
        assert "participant=1_session=1_source=apple.json" = filename
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, "data", %{
                 "identifier" => [[:participant, 1], [:session, 1], [:source, "apple"]]
               })
    end

    test "folder + participant + meta key + source=nil" do
      expect(MockSpecial, :store, fn folder, filename, _data ->
        assert "assignment=1" = folder
        assert "participant=1_session=1_source=.json" = filename
        :ok
      end)

      assert :ok =
               Backend.store(%{"key" => "assignment=1"}, "data", %{
                 "identifier" => [[:participant, 1], [:session, 1], [:source, nil]]
               })
    end
  end
end
