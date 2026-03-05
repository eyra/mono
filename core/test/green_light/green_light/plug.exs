defmodule Core.Authorization.Plug.ControllerAuthorizationTest do
  use Core.DataCase

  import Plug.Conn
  import Plug.Test

  alias Core.Authorization.PermissionMap
  alias Core.Authorization.Plug.ControllerAuthorization
  alias Plug.Conn
  alias Systems.Account

  defmodule TestStruct do
    @moduledoc false
    defstruct id: ""
  end

  @permission_map PermissionMap.grant(PermissionMap.new(), :access_example_controller, :admin)
  @opts ControllerAuthorization.init(@permission_map)

  @admin %{
    email: "admin@example.org",
    password: "S4p3rS3cr3t",
    password_confirmation: "S4p3rS3cr3t"
  }

  def admin_fixture(attrs \\ %{}) do
    {:ok, user} = attrs |> Enum.into(@admin) |> Account.Public.create()
    user
  end

  test "deny by default" do
    # Create a test connection
    conn =
      :get
      |> conn("/example", %{"test" => "some-id"})
      |> EntityExtractor.call(@opts)

    assert conn.assigns.entities == %{"test" => %TestStruct{id: "some-id"}}
  end

  test "allow principal with proper role grants to access controller" do
  end

  test "disallow principal without matching roles to access controller" do
  end

  test "allow anonymous users to access a explictly public controller" do
  end

  test "disallow access on nested entity when any (sub) entity has non-matching role requirements" do
  end

  test "allow access on a nested entity" do
  end
end
