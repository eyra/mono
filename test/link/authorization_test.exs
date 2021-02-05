defmodule Link.AuthorizationTest do
  alias GreenLight.Principal
  alias Link.Authorization
  alias Link.Factories
  use Link.DataCase

  test "principal returns `visitor` for nil users" do
    assert Authorization.principal(nil) == %Principal{id: nil, roles: MapSet.new([:visitor])}
  end

  test "principal returns `member` for regular users" do
    member = Factories.insert!(:member)

    assert Authorization.principal(member) == %Principal{
             id: member.id,
             roles: MapSet.new([:member])
           }
  end

  test "principal returns `member` and `researcher` for users marked as such" do
    researcher = Factories.insert!(:researcher)

    assert Authorization.principal(researcher) == %Principal{
             id: researcher.id,
             roles: MapSet.new([:member, :researcher])
           }
  end

  test "can create authorization node" do
    {:ok, _node} = Authorization.create_node()
  end

  test "can create authorization child node" do
    {:ok, parent} = Authorization.create_node()
    {:ok, child} = Authorization.create_node(parent)
    assert child != parent
  end

  test "can get parent authorization nodes" do
    # Setup some trees to test against
    {:ok, a} = Authorization.create_node()
    {:ok, a_a} = Authorization.create_node(a)
    {:ok, a_a_a} = Authorization.create_node(a_a)
    {:ok, _a_b} = Authorization.create_node(a)
    {:ok, _b} = Authorization.create_node()

    parents = Authorization.get_parent_nodes(a_a_a)
    assert parents == [a_a_a, a_a, a]
  end

  test "can assign role to authorization node" do
    {:ok, node} = Authorization.create_node()
    :ok = Authorization.assign_role(1, node, :owner)
  end

  test "role intersection on a node" do
    {:ok, node} = Authorization.create_node()
    # Nothing intersects when not assigned
    refute Authorization.roles_intersect?(1, node, [:owner])
    # Assignment for a different principal does not result in an intersection
    refute Authorization.roles_intersect?(9, node, [:owner])
    # Assignment on the node results in an intersection
    :ok = Authorization.assign_role(1, node, :owner)
    assert Authorization.roles_intersect?(1, node, [:owner])
  end

  test "role intersection works on sub-nodes" do
    {:ok, node} = Authorization.create_node()
    {:ok, sub_node} = Authorization.create_node(node)
    # Nothing intersects when not assigned
    refute Authorization.roles_intersect?(1, sub_node, [:owner])
    # A role assignment on the parent affects the sub-nodes
    :ok = Authorization.assign_role(1, node, :owner)
    assert Authorization.roles_intersect?(1, sub_node, [:owner])
    # It fails with non-intersecting roles
    {:ok, second_node} = Authorization.create_node()
    {:ok, second_sub_node} = Authorization.create_node(second_node)
    refute Authorization.roles_intersect?(1, second_sub_node, [:owner])
  end

  test "can check for permission against a node" do
    {:ok, node} = Authorization.create_node()
    # The permission is denied by default
    refute Authorization.can?(1, node, "test-auth")
    # Assignment on the node makes the access allowed
    :ok = Authorization.assign_role(1, node, :owner)
    assert Authorization.can?(1, node, "test-auth")
  end
end
