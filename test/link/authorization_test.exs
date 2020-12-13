defmodule Link.AuthorizationTest do
  alias GreenLight.Principal
  alias Link.Authorization
  alias Link.Factories
  use Link.DataCase

  test "principal returns `visitor` for nil users" do
    assert Authorization.principal(nil) == %Principal{id: nil, roles: MapSet.new([:visitor])}
  end

  test "principal returns `member` for regular users" do
    member = Factories.get_or_create_user()

    assert Authorization.principal(member) == %Principal{
             id: member.id,
             roles: MapSet.new([:member])
           }
  end

  test "principal returns `member` and `researcher` for users marked as such" do
    researcher = Factories.get_or_create_researcher()

    assert Authorization.principal(researcher) == %Principal{
             id: researcher.id,
             roles: MapSet.new([:member, :researcher])
           }
  end
end
