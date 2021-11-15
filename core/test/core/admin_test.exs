defmodule Core.AdminTest do
  use ExUnit.Case, async: true
  alias Core.Admin

  describe "admin?/2" do
    test "full match" do
      compiled = Admin.compile(["test@example.org", "another@example.org"])
      assert Admin.admin?(compiled, "test@example.org")
      assert Admin.admin?(compiled, "another@example.org")
    end

    test "non-match" do
      refute Admin.admin?(Admin.compile(["test@example.org"]), "something@example.org")
    end

    test "nil" do
      refute Admin.admin?(Admin.compile(["test@example.org"]), nil)
    end

    test "pattern-match" do
      compiled = Admin.compile(["*@example.org"])
      assert Admin.admin?(compiled, "example@example.org")
      assert Admin.admin?(compiled, "test.ing@example.org")
      assert Admin.admin?(compiled, "test-ing@example.org")
      assert Admin.admin?(compiled, "test_ing@example.org")
    end

    test "pattern-match excludes non-matching" do
      refute Admin.admin?(Admin.compile(["*@example.org"]), "example@example.com")
    end

    test "non-compiled works" do
      assert Admin.admin?(["*@example.org"], "test@example.org")
      refute Admin.admin?(["*@example.org"], "test@example.com")
    end
  end
end
