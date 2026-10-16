defmodule Systems.Account.Auth.CenterdataTest do
  use Core.DataCase, async: true

  alias Core.Factories
  alias Systems.Account.Auth.Centerdata

  test "uses a verified email for the account" do
    attrs =
      Centerdata.user_attrs(%{
        "sub" => "123",
        "email" => "panel@example.com",
        "email_verified" => true
      })

    assert attrs.email == "panel@example.com"
    assert %NaiveDateTime{} = attrs.confirmed_at
  end

  test "rejects an unverified email" do
    assert_raise Centerdata.CenterdataError, fn ->
      Centerdata.user_attrs(%{
        "sub" => "123",
        "email" => "panel@example.com",
        "email_verified" => false
      })
    end
  end

  test "attaches the permanent Centerdata subject" do
    user = Factories.insert!(:member, %{email: "panel@example.com"})
    userinfo = %{"sub" => "123", "email" => user.email, "email_verified" => true}

    {:ok, identity} = Centerdata.attach(user, userinfo)

    assert identity.user_id == user.id
    assert identity.sub == "123"
    assert identity.userinfo == userinfo
  end
end
