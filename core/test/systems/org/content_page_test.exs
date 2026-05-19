defmodule Systems.Org.ContentPageTest do
  @moduledoc """
  Regression coverage for FX#9905888394 — /org/node/{id} must not be
  accessible to users who don't manage that specific org, even if they
  happen to own (or used to own) another org and therefore carry the
  global :admin role.
  """
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Org

  describe "access control" do
    test "owner of the org can access content page", ctx do
      user = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["content_page_owner_org"]})
      :ok = Org.Public.assign_owner(org, user)

      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn]

      assert {:ok, _view, _html} = live(conn, ~p"/org/node/#{org.id}")
    end

    test "owner of one org is denied access to an org they don't manage", ctx do
      user = Factories.insert!(:creator)
      owned_org = Factories.insert!(:org_node, %{identifier: ["cp_owned_org"]})
      other_org = Factories.insert!(:org_node, %{identifier: ["cp_other_org"]})
      :ok = Org.Public.assign_owner(owned_org, user)

      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn]

      assert {:error, {:redirect, %{to: "/access_denied"}}} =
               live(conn, ~p"/org/node/#{other_org.id}")
    end

    test "access is denied after the owner role is revoked", ctx do
      user = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["cp_revoked_org"]})
      :ok = Org.Public.assign_owner(org, user)

      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn]

      assert {:ok, _view, _html} = live(conn, ~p"/org/node/#{org.id}")

      :ok = Org.Public.revoke_owner(org, user)

      assert {:error, {:redirect, %{to: "/access_denied"}}} =
               live(conn, ~p"/org/node/#{org.id}")
    end
  end
end
