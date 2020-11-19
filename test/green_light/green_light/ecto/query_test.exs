defmodule Link.Authorization.DBTest do
  # use Link.DataCase

  # alias Link.Users.User
  # alias Link.Authorization.TestEntity
  # alias Link.Authorization.DB

  # describe "list_roles" do
  #   test "returns empty set for nil principal" do
  #     assert DB.list_roles(nil, %{}) == MapSet.new()
  #   end

  #   test "returns empty set for principal without role assignments" do
  #     assert DB.list_roles(%User{id: 1}, %TestEntity{id: 2}) == MapSet.new()
  #   end

  #   test "returns the roles that have been assigned" do
  #     principal = %User{id: 1}
  #     entity = %TestEntity{id: 2}
  #     DB.assign_role!(principal, entity, :researcher)
  #     assert DB.list_roles(principal, entity) == MapSet.new([:researcher])
  #   end
  # end
end
