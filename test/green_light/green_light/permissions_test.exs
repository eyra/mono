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

  # test "can? returns true / false based on wheter or not the user has permission" do
  #   conn =
  #     build_conn(:get, "/")
  #     |> Plug.Conn.put_private(:phoenix_controller, LinkWeb.StudyController)
  #     |> Pow.Plug.put_config([])
  #     |> Pow.Plug.assign_current_user(%Link.Users.User{id: 9}, otp_app: :link_web)

  #   refute Controller.can?(conn, :edit, %Link.Studies.Study{id: 1234})
  #   assert Controller.can?(conn, :show, %Link.Studies.Study{id: 1234})
  #   assert Controller.can?(conn, :index)
  # end
end
