defmodule Systems.Admin.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Admin.Public

  describe "has_governable_entities?/1" do
    test "returns true when user owns at least one organisation" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["test_org"]})
      Core.Authorization.assign_role(user, org, :owner)

      assert Public.has_governable_entities?(user)
    end

    test "returns false when user owns no organisations" do
      user = Factories.insert!(:member)
      refute Public.has_governable_entities?(user)
    end

    test "returns false for nil" do
      refute Public.has_governable_entities?(nil)
    end
  end

  describe "admin?/2" do
    test "full match" do
      compiled = Public.compile(["test@example.org", "another@example.org"])
      assert Public.admin?(compiled, "test@example.org")
      assert Public.admin?(compiled, "another@example.org")
    end

    test "non-match" do
      refute Public.admin?(Public.compile(["test@example.org"]), "something@example.org")
    end

    test "nil" do
      refute Public.admin?(Public.compile(["test@example.org"]), nil)
    end

    test "pattern-match" do
      compiled = Public.compile(["*@example.org"])
      assert Public.admin?(compiled, "example@example.org")
      assert Public.admin?(compiled, "test.ing@example.org")
      assert Public.admin?(compiled, "test-ing@example.org")
      assert Public.admin?(compiled, "test_ing@example.org")
    end

    test "pattern-match excludes non-matching" do
      refute Public.admin?(Public.compile(["*@example.org"]), "example@example.com")
    end

    test "non-compiled works" do
      assert Public.admin?(["*@example.org"], "test@example.org")
      refute Public.admin?(["*@example.org"], "test@example.com")
    end
  end
end
