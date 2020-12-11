defmodule Link.AuthorizationTest do
  alias GreenLight.Principal
  alias Link.Authorization
  use ExUnit.Case, async: true

  test "principal returns `visitor` for nil users" do
    assert Authorization.principal(nil) == %Principal{id: nil, roles: MapSet.new([:visitor])}
  end

  test "principal returns `member` for regular users" do
    assert Authorization.principal(%Link.Users.User{id: 123}) == %Principal{
             id: 123,
             roles: MapSet.new([:member])
           }
  end
end
