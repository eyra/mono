defmodule GreenLight.Test do
  # alias GreenLight.Permissions
  # use GreenLight.DataCase
  # require Ecto.Query

  # defmodule Foo do
  #   use Ecto.Schema, async: false

  #   @primary_key false
  #   embedded_schema do
  #     field :id, :string
  #   end
  # end

  # defmodule Bar do
  #   defstruct id: "bar"
  # end

  # describe "role_assignments" do
  #   alias Link.AuthorizationTest.Foo
  #   alias Link.AuthorizationTest.Bar

  #   @principal %Link.Users.User{id: 9}
  #   @second_principal %Link.Users.User{id: 10}

  #   test "assign_role adds entry that can be found with list_roles" do
  #     Authorization.assign_role!(@principal, %Foo{id: 1}, :researcher)
  #     assert Authorization.list_roles(@principal, %Foo{id: 1}) == MapSet.new([:researcher])
  #   end

  #   test "list_roles only list roles for the specified principal" do
  #     Authorization.assign_role!(@principal, %Foo{id: 123}, :researcher)
  #     Authorization.assign_role!(@second_principal, %Foo{id: 123}, :visitor)
  #     assert Authorization.list_roles(@principal, %Foo{id: 123}) == MapSet.new([:researcher])
  #   end

  #   test "list_roles only list roles for the specified entity type" do
  #     Authorization.assign_role!(@principal, %Foo{id: 321}, :researcher)
  #     Authorization.assign_role!(@principal, %Bar{id: 321}, :visitor)
  #     assert Authorization.list_roles(@principal, %Foo{id: 321}) == MapSet.new([:researcher])
  #   end

  #   test "list_roles only list roles for the specified entity id" do
  #     Authorization.assign_role!(@principal, %Foo{id: 1}, :researcher)
  #     Authorization.assign_role!(@principal, %Foo{id: 2}, :member)
  #     assert Authorization.list_roles(@principal, %Foo{id: 1}) == MapSet.new([:researcher])
  #   end
  # end
end
