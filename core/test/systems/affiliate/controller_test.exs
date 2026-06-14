defmodule Systems.Affiliate.ControllerTest do
  use ExUnit.Case, async: true

  alias Systems.Affiliate.Controller

  describe "valid_id?/1" do
    test "rejects nil" do
      refute Controller.valid_id?(nil)
    end

    test "rejects \"participant_id\" placeholder" do
      refute Controller.valid_id?("participant_id")
    end

    test "rejects \"null\" string" do
      refute Controller.valid_id?("null")
    end

    test "rejects \"undefined\" string" do
      refute Controller.valid_id?("undefined")
    end

    test "rejects empty string" do
      refute Controller.valid_id?("")
    end

    test "rejects identifiers longer than 64 characters" do
      refute Controller.valid_id?(String.duplicate("a", 65))
    end

    test "rejects identifiers containing whitespace" do
      refute Controller.valid_id?("foo bar")
    end

    test "rejects identifiers containing special characters" do
      refute Controller.valid_id?("foo@bar")
    end

    test "accepts alphanumeric identifier" do
      assert Controller.valid_id?("abc123")
    end

    test "accepts identifier with underscores and hyphens" do
      assert Controller.valid_id?("foo_bar-baz")
    end

    test "accepts 36-character UUID-like identifier" do
      assert Controller.valid_id?("550e8400e29b41d4a716446655440000")
    end
  end
end
