defmodule GreenLight.PermissionMapTest do
  alias GreenLight.PermissionMap
  use ExUnit.Case, async: true

  test "grant and new create the same structure" do
    a = PermissionMap.new(%{view: [:visitor, :member], edit: [:researcher, :admin]})

    b =
      PermissionMap.new()
      |> PermissionMap.grant(:view, [:visitor, :member])
      |> PermissionMap.grant(:edit, [:researcher, :admin])

    assert a == b
  end

  test "roles returns all roles registered for a permission" do
    permission_map =
      PermissionMap.new()
      |> PermissionMap.grant(:read_stuff, :researcher)
      |> PermissionMap.grant(:read_stuff, :tester)

    assert PermissionMap.roles(permission_map, :read_stuff) ==
             MapSet.new([:researcher, :tester])

    assert PermissionMap.roles(permission_map, :undefined_permission) == MapSet.new()
  end

  test "grant multiple roles at once" do
    permission_map =
      PermissionMap.new()
      |> PermissionMap.grant(:read_stuff, [:researcher, :participant])

    assert PermissionMap.roles(permission_map, :read_stuff) ==
             MapSet.new([:researcher, :participant])
  end

  test "allowed? checks for matching roles" do
    permission_map =
      PermissionMap.new()
      |> PermissionMap.grant(:read_stuff, :researcher)
      |> PermissionMap.grant(:read_stuff, :tester)

    assert PermissionMap.allowed?(permission_map, :read_stuff, [:tester])
    refute PermissionMap.allowed?(permission_map, :read_stuff, [:nobody])
    refute PermissionMap.allowed?(permission_map, :edit_stuff, [:tester])
  end

  test "merge-ing two maps results in the combined version" do
    a = PermissionMap.new(%{view: :member, edit: :researcher, detail: :member})
    b = PermissionMap.new(%{view: :visitor, edit: [:researcher, :admin], list: :admin})

    assert PermissionMap.merge(a, b) ==
             PermissionMap.new(%{
               detail: [:member],
               edit: [:admin, :researcher],
               list: [:admin],
               view: [:visitor, :member]
             })
  end

  test "merge-ing either argument an empty maps works" do
    permission_map =
      PermissionMap.new(%{view: :visitor, edit: [:researcher, :admin], list: :admin})

    assert PermissionMap.merge(%{}, permission_map) == permission_map
    assert PermissionMap.merge(permission_map, %{}) == permission_map
    assert PermissionMap.merge(%{}, %{}) == %{}
  end

  test "list roles returns a sorted role maps" do
    permission_map =
      PermissionMap.new(%{
        view: :member,
        edit: [:researcher, :admin],
        detail: :member
      })

    assert PermissionMap.list_permission_assignments(permission_map) == [
             detail: [:member],
             edit: [:admin, :researcher],
             view: [:member]
           ]
  end
end
