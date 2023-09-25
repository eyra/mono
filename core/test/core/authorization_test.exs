defmodule Core.AuthorizationTest do
  alias Core.Authorization
  alias Core.Factories
  use Core.DataCase
  alias Core.Accounts.User
  alias Frameworks.GreenLight.Principal

  test "principal returns `visitor` for nil users" do
    assert Principal.id(nil) == nil
    assert Principal.roles(nil) == MapSet.new([:visitor])
  end

  test "principal returns `member` for regular users" do
    member = Factories.insert!(:member)

    assert Principal.id(member) == member.id
    assert Principal.roles(member) == MapSet.new([:member])
  end

  test "principal returns `member` and `researcher` for users marked as such" do
    researcher = Factories.insert!(:researcher)
    assert Principal.roles(researcher) == MapSet.new([:member, :researcher])
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
    :ok = Authorization.assign_role(%User{id: 1}, node, :owner)
  end

  test "can get user for role" do
    %{id: id, email: email} = user = Factories.insert!(:researcher)
    {:ok, node} = Authorization.create_node()
    :ok = Authorization.assign_role(user, node, :owner)

    assert [%{id: ^id, email: ^email}] = Authorization.users_with_role(node, :owner)
  end

  test "can't get user for role" do
    user = Factories.insert!(:researcher)
    {:ok, node} = Authorization.create_node()
    :ok = Authorization.assign_role(user, node, :owner)

    assert [] = Authorization.users_with_role(node, :participant)
  end

  test "role intersection on a node" do
    {:ok, node} = Authorization.create_node()
    # Nothing intersects when not assigned
    refute Authorization.roles_intersect?(%User{id: 1}, node, [:owner])
    # Assignment for a different principal does not result in an intersection
    refute Authorization.roles_intersect?(%User{id: 9}, node, [:owner])
    # Assignment on the node results in an intersection
    :ok = Authorization.assign_role(%User{id: 1}, node, :owner)
    assert Authorization.roles_intersect?(%User{id: 1}, node, [:owner])
  end

  test "role intersection works on sub-nodes" do
    {:ok, node} = Authorization.create_node()
    {:ok, sub_node} = Authorization.create_node(node)
    # Nothing intersects when not assigned
    refute Authorization.roles_intersect?(%User{id: 1}, sub_node, [:owner])
    # A role assignment on the parent affects the sub-nodes
    :ok = Authorization.assign_role(%User{id: 1}, node, :owner)
    assert Authorization.roles_intersect?(%User{id: 1}, sub_node, [:owner])
    # It fails with non-intersecting roles
    {:ok, second_node} = Authorization.create_node()
    {:ok, second_sub_node} = Authorization.create_node(second_node)
    refute Authorization.roles_intersect?(%User{id: 1}, second_sub_node, [:owner])
  end

  test "can_access?/3 fail for entity == nil" do
    assert Authorization.can_access?(%User{id: 1}, nil, Systems.Benchmark.ToolPage) == false
  end

  test "can_access?/3 fail for entity without roles" do
    {:ok, node_id} = Authorization.create_node()
    assert Authorization.can_access?(%User{id: 1}, node_id, Systems.Benchmark.ToolPage) == false
  end

  test "can_access?/3 succeeds for entity with suffient rights" do
    principal = %User{id: 1}
    {:ok, node_id} = Authorization.create_node()
    Authorization.assign_role(principal, node_id, :owner)
    assert Authorization.can_access?(principal, node_id, Systems.Benchmark.ToolPage) == true
  end

  test "link/1 succeeds tuple with parent/child" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id} = child = Authorization.create_node!()

    Authorization.link({parent, child})

    assert %Core.Authorization.Node{
             id: ^child_id,
             parent: %Core.Authorization.Node{
               id: ^parent_id,
               parent_id: nil
             }
           } = Repo.get!(Core.Authorization.Node, child.id) |> Repo.preload(:parent)
  end

  test "link/1 succeeds tuple with parent/childs" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id1} = child1 = Authorization.create_node!()
    %{id: child_id2} = child2 = Authorization.create_node!()

    Authorization.link({parent, [child1, child2]})

    assert %Core.Authorization.Node{
             id: ^child_id1,
             parent: %Core.Authorization.Node{
               id: ^parent_id,
               parent_id: nil
             }
           } = Repo.get!(Core.Authorization.Node, child1.id) |> Repo.preload(:parent)

    assert %Core.Authorization.Node{
             id: ^child_id2,
             parent: %Core.Authorization.Node{
               id: ^parent_id,
               parent_id: nil
             }
           } = Repo.get!(Core.Authorization.Node, child2.id) |> Repo.preload(:parent)
  end

  test "link/1 succeeds tuple with parent/tuple-list" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id_a} = child_a = Authorization.create_node!()
    %{id: child_id_a_a} = child_a_a = Authorization.create_node!()
    %{id: child_id_a_b} = child_a_b = Authorization.create_node!()

    Authorization.link({parent, {child_a, [child_a_a, child_a_b]}})

    assert %Core.Authorization.Node{
             id: ^child_id_a_a,
             parent: %Core.Authorization.Node{
               id: ^child_id_a,
               parent: %Core.Authorization.Node{
                 id: ^parent_id,
                 parent_id: nil
               }
             }
           } = Repo.get!(Core.Authorization.Node, child_a_a.id) |> Repo.preload(parent: [:parent])

    assert %Core.Authorization.Node{
             id: ^child_id_a_b,
             parent: %Core.Authorization.Node{
               id: ^child_id_a,
               parent: %Core.Authorization.Node{
                 id: ^parent_id,
                 parent_id: nil
               }
             }
           } = Repo.get!(Core.Authorization.Node, child_a_b.id) |> Repo.preload(parent: [:parent])
  end

  test "link/1 succeeds tuple with parent/tuple-list with nil value" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id_a} = child_a = Authorization.create_node!()
    %{id: child_id_a_a} = child_a_a = Authorization.create_node!()

    Authorization.link({parent, {child_a, [child_a_a, nil]}})

    assert %Core.Authorization.Node{
             id: ^child_id_a_a,
             parent: %Core.Authorization.Node{
               id: ^child_id_a,
               parent: %Core.Authorization.Node{
                 id: ^parent_id,
                 parent_id: nil
               }
             }
           } = Repo.get!(Core.Authorization.Node, child_a_a.id) |> Repo.preload(parent: [:parent])
  end

  test "link/1 succeeds tuple with parent/tuple-item" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id_a} = child_a = Authorization.create_node!()
    %{id: child_id_a_a} = child_a_a = Authorization.create_node!()

    Authorization.link({parent, {child_a, child_a_a}})

    assert %Core.Authorization.Node{
             id: ^child_id_a_a,
             parent: %Core.Authorization.Node{
               id: ^child_id_a,
               parent: %Core.Authorization.Node{
                 id: ^parent_id,
                 parent_id: nil
               }
             }
           } = Repo.get!(Core.Authorization.Node, child_a_a.id) |> Repo.preload(parent: [:parent])
  end

  test "link/1 succeeds tuple with parent/tuple-item with nil value" do
    %{id: parent_id} = parent = Authorization.create_node!()
    %{id: child_id_a} = child_a = Authorization.create_node!()

    Authorization.link({parent, {child_a, nil}})

    assert %Core.Authorization.Node{
             id: ^child_id_a,
             parent: %Core.Authorization.Node{
               id: ^parent_id,
               parent_id: nil
             }
           } = Repo.get!(Core.Authorization.Node, child_a.id) |> Repo.preload(parent: [:parent])
  end
end
