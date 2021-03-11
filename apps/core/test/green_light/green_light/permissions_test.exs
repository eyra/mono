defmodule TestEntity do
  defstruct id: nil
end

defmodule GreenLight.PermissionsTest do
  alias GreenLight.Permissions
  alias GreenLight.PermissionMap
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
