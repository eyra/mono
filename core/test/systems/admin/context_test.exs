defmodule Systems.Admin.ContextTest do
  use ExUnit.Case, async: true
  alias Systems.Admin.Context

  describe "admin?/2" do
    test "full match" do
      compiled = Context.compile(["test@example.org", "another@example.org"])
      assert Context.admin?(compiled, "test@example.org")
      assert Context.admin?(compiled, "another@example.org")
    end

    test "non-match" do
      refute Context.admin?(Context.compile(["test@example.org"]), "something@example.org")
    end

    test "nil" do
      refute Context.admin?(Context.compile(["test@example.org"]), nil)
    end

    test "pattern-match" do
      compiled = Context.compile(["*@example.org"])
      assert Context.admin?(compiled, "example@example.org")
      assert Context.admin?(compiled, "test.ing@example.org")
      assert Context.admin?(compiled, "test-ing@example.org")
      assert Context.admin?(compiled, "test_ing@example.org")
    end

    test "pattern-match excludes non-matching" do
      refute Context.admin?(Context.compile(["*@example.org"]), "example@example.com")
    end

    test "non-compiled works" do
      assert Context.admin?(["*@example.org"], "test@example.org")
      refute Context.admin?(["*@example.org"], "test@example.com")
    end
  end
end
