defmodule Systems.Pool.AccountPostActionHandlerTest do
  use Core.DataCase

  alias Systems.Pool
  alias Systems.Pool.AccountPostActionHandler

  describe "handle/2 with creator account" do
    test "skips processing for creator account with add_to_panl action" do
      creator = Factories.insert!(:member, %{creator: true})

      assert :ok = AccountPostActionHandler.handle(creator, "add_to_panl")

      # Creator should NOT be added to PaNL pool
      refute Pool.Public.participant?(:panl, creator)
    end

    test "skips processing for creator account with unknown action" do
      creator = Factories.insert!(:member, %{creator: true})

      assert :ok = AccountPostActionHandler.handle(creator, "unknown_action")
    end
  end

  describe "handle/2 with add_to_panl action" do
    test "adds non-creator user to PaNL pool" do
      user = Factories.insert!(:member, %{creator: false})
      _panl_pool = Pool.Assembly.get_or_create_panl()

      refute Pool.Public.participant?(:panl, user)

      assert :ok = AccountPostActionHandler.handle(user, "add_to_panl")

      assert Pool.Public.participant?(:panl, user)
    end

    test "succeeds when PaNL pool does not exist" do
      user = Factories.insert!(:member, %{creator: false})

      # Ensure PaNL pool doesn't exist
      if panl_pool = Pool.Public.get_panl() do
        Repo.delete(panl_pool)
      end

      # Should still return :ok (silently fails)
      assert :ok = AccountPostActionHandler.handle(user, "add_to_panl")
    end

    test "is idempotent - adding same user twice succeeds" do
      user = Factories.insert!(:member, %{creator: false})
      _panl_pool = Pool.Assembly.get_or_create_panl()

      assert :ok = AccountPostActionHandler.handle(user, "add_to_panl")
      assert :ok = AccountPostActionHandler.handle(user, "add_to_panl")

      assert Pool.Public.participant?(:panl, user)
    end
  end

  describe "handle/2 with unknown action" do
    test "returns :ok for unknown action" do
      user = Factories.insert!(:member, %{creator: false})

      # Unknown actions are silently ignored (logged as warning, returns :ok)
      assert :ok = AccountPostActionHandler.handle(user, "unknown_action")
    end

    test "does not add user to any pool for unknown action" do
      user = Factories.insert!(:member, %{creator: false})
      _panl_pool = Pool.Assembly.get_or_create_panl()

      AccountPostActionHandler.handle(user, "unknown_action")

      refute Pool.Public.participant?(:panl, user)
    end
  end
end
