defmodule Systems.Storage.Azure.BackendTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.Azure.Backend

  describe "filename/1" do
    test "empty identifier" do
      assert ".json" = Backend.filename([])
    end

    test "single identifier" do
      assert "participant-1.json" = Backend.filename([[:participant, 1]])
    end

    test "multiple identifiers" do
      identifier = [[:assignment, 1], [:participant, "abc"], [:source, "test"]]
      assert "assignment-1_participant-abc_source-test.json" = Backend.filename(identifier)
    end
  end
end
