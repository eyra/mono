defmodule TestEntity do
  defstruct id: nil
end

defmodule Frameworks.GreenLight.PermissionsTest do
  alias Frameworks.GreenLight.{Permissions, PermissionMap}
  use ExUnit.Case, async: true

  test "action_permission returns a permission string" do
    assert Permissions.action_permission(
             :"Elixir.MyProjectWeb.SomeFancyController",
             :view
           ) ==
             "invoke/my_project_web/some_fancy_controller@view"

    1
  end

  test "actions_permission_map returns a permission map from the provided mapping" do
    assert Permissions.actions_permission_map(
             SomeAppWeb.AnotherController,
             %{index: [:role_a, :role_b], show: [:role_a]}
           ) ==
             PermissionMap.new(%{
               "invoke/some_app_web/another_controller@index" => [:role_a, :role_b],
               "invoke/some_app_web/another_controller@show" => [:role_a]
             })
  end
end

defmodule Frameworks.GreenLight.PermissionsTest.Grants do
  def grants do
    send(self(), :grants_read)
    [{SomeAppWeb.Page, [:member]}, {SomeAppWeb.AnotherController, %{index: [:role_a]}}]
  end
end

defmodule Frameworks.GreenLight.PermissionsTest.Authorization do
  use Frameworks.GreenLight.Public,
    repo: SomeApp.Repo,
    roles: [:member, :owner, :role_a],
    role_assignment_schema: SomeApp.RoleAssignment,
    grants: {Frameworks.GreenLight.PermissionsTest.Grants, :grants, []}

  grant_access(SomeAppWeb.OwnerPage, [:owner])
end

defmodule Frameworks.GreenLight.RuntimeGrantsTest do
  alias Frameworks.GreenLight.{Permissions, PermissionMap}
  alias Frameworks.GreenLight.PermissionsTest.Authorization
  use ExUnit.Case, async: true

  test "grants given as data become access and action permissions" do
    assert Permissions.grants_permission_map(PermissionMap.new(), [
             {SomeAppWeb.Page, [:member]},
             {SomeAppWeb.AnotherController, %{index: [:role_a], show: [:role_b]}}
           ]) ==
             PermissionMap.new(%{
               "access/some_app_web/page" => [:member],
               "invoke/some_app_web/another_controller@index" => [:role_a],
               "invoke/some_app_web/another_controller@show" => [:role_b]
             })
  end

  test "a permission granted twice is an error, not a widening" do
    assert_raise ArgumentError, ~r/^access\/some_app_web\/page is granted more than once;/, fn ->
      Permissions.grants_permission_map(PermissionMap.new(), [
        {SomeAppWeb.Page, [:member]},
        {SomeAppWeb.Page, [:owner]}
      ])
    end
  end

  test "a grant of a permission the map already has is an error" do
    permission_map = PermissionMap.new(%{"access/some_app_web/page" => [:member]})

    assert_raise ArgumentError, ~r/^access\/some_app_web\/page is granted more than once;/, fn ->
      Permissions.grants_permission_map(permission_map, [{SomeAppWeb.Page, [:owner]}])
    end
  end

  test "a grant that says widen: true adds its roles to the permission" do
    assert Permissions.grants_permission_map(PermissionMap.new(), [
             {SomeAppWeb.Page, [:member]},
             {SomeAppWeb.Page, [:owner], widen: true}
           ]) == PermissionMap.new(%{"access/some_app_web/page" => [:member, :owner]})
  end

  test "an action grant that says widen: true adds its roles to the action" do
    permission_map =
      PermissionMap.new(%{"invoke/some_app_web/another_controller@index" => [:role_a]})

    assert Permissions.grants_permission_map(permission_map, [
             {SomeAppWeb.AnotherController, %{index: [:role_b]}, widen: true}
           ]) ==
             PermissionMap.new(%{
               "invoke/some_app_web/another_controller@index" => [:role_a, :role_b]
             })
  end

  test "a grant that says widen: true of a permission not granted before is an error" do
    assert_raise ArgumentError,
                 "access/some_app_web/page is not granted before, so `widen: true` widens nothing",
                 fn ->
                   Permissions.grants_permission_map(PermissionMap.new(), [
                     {SomeAppWeb.Page, [:owner], widen: true}
                   ])
                 end
  end

  test "changed runtime grants replace the cached map" do
    # A module name of its own: the cache is per module.
    module = Frameworks.GreenLight.RuntimeGrantsTest.Regranted
    permission_map = PermissionMap.new()

    Permissions.runtime_permission_map(module, permission_map, {Function, :identity, [[]]})

    merged =
      Permissions.runtime_permission_map(
        module,
        permission_map,
        {Function, :identity, [[{SomeAppWeb.Page, [:member]}]]}
      )

    assert PermissionMap.roles(merged, "access/some_app_web/page") == MapSet.new([:member])
  end

  test "a recompiled module's changed compiled grants replace the cached map" do
    # A module name of its own: the cache is per module.
    module = Frameworks.GreenLight.RuntimeGrantsTest.Recompiled
    grants = {Frameworks.GreenLight.PermissionsTest.Grants, :grants, []}
    before = PermissionMap.new(%{"access/some_app_web/owner_page" => [:owner]})
    edited = PermissionMap.new(%{"access/some_app_web/owner_page" => [:owner, :member]})

    Permissions.runtime_permission_map(module, before, grants)
    merged = Permissions.runtime_permission_map(module, edited, grants)

    assert PermissionMap.roles(merged, "access/some_app_web/owner_page") ==
             MapSet.new([:owner, :member])
  end

  test "the grants option merges runtime grants into the compiled ones" do
    expected =
      PermissionMap.new(%{
        "access/some_app_web/owner_page" => [:owner],
        "access/some_app_web/page" => [:member],
        "invoke/some_app_web/another_controller@index" => [:role_a]
      })

    assert Authorization.permission_map() == expected
    assert Authorization.permission_map() == expected
    assert Authorization.allowed?([:member], "access/some_app_web/page")

    assert_received :grants_read
  end
end
