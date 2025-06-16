defmodule Systems.Affiliate.PublicTest do
  use Core.DataCase

  alias Systems.Affiliate

  describe "redirect_url" do
    setup do
      member = Factories.insert!(:member)
      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_user"})

      info =
        Factories.insert!(:affiliate_user_info, %{
          user: affiliate_user,
          info: Jason.encode!(%{p: "1234", q: "tester"})
        })

      %{affiliate_user: affiliate_user, member: member, info: info}
    end

    test "error if no affiliate is given", %{affiliate_user: affiliate_user} do
      assert_raise FunctionClauseError, fn ->
        Affiliate.Public.redirect_url(nil, affiliate_user)
      end
    end

    test "returns nil if normal member is given", %{member: member} do
      affiliate = Factories.insert!(:affiliate)
      assert Affiliate.Public.redirect_url(affiliate, member) == {:error, :user_not_found}
    end

    test "returns nil if no user is given" do
      affiliate =
        Factories.insert!(:affiliate, %{redirect_url: "http://some.domain.com/redirect?r=3"})

      assert Affiliate.Public.redirect_url(affiliate, nil) == {:error, :user_missing}
    end

    test "returns nil if no redirect_url is given", %{affiliate_user: affiliate_user} do
      affiliate = Factories.insert!(:affiliate)

      assert Affiliate.Public.redirect_url(affiliate, affiliate_user) ==
               {:error, :redirect_url_missing}
    end

    test "returns url with info", %{affiliate_user: affiliate_user} do
      affiliate =
        Factories.insert!(:affiliate, %{redirect_url: "http://some.domain.com/redirect?r=3"})

      assert Affiliate.Public.redirect_url(affiliate, affiliate_user) ==
               {:ok, "http://some.domain.com/redirect?p=1234&q=tester&r=3"}
    end
  end

  describe "send_progress_event" do
    setup do
      affiliate =
        Factories.insert!(:affiliate, %{callback_url: "http://some.domain.com/callback"})

      affiliate_user = Factories.insert!(:affiliate_user, %{identifier: "test_user"})
      info = nil

      %{
        affiliate: affiliate,
        affiliate_user: affiliate_user,
        info: info,
        event: %{event: "test_event"}
      }
    end

    test "error if no affiliate is given", %{affiliate_user: %{user: user}, event: event} do
      assert {:error, :affiliate_url_missing} = Affiliate.Public.send_event(nil, event, user)
    end

    test "error if no user is given", %{affiliate: affiliate, event: event} do
      assert {:error, :user_missing} = Affiliate.Public.send_event(affiliate, event, nil)
    end

    test "error if no event is given", %{affiliate: affiliate, affiliate_user: %{user: user}} do
      assert {:error, :event_missing} = Affiliate.Public.send_event(affiliate, nil, user)
    end

    test "error if wrong event format is given", %{
      affiliate: affiliate,
      affiliate_user: %{user: user}
    } do
      assert {:error, :event_invalid_format} =
               Affiliate.Public.send_event(affiliate, "test_event", user)
    end

    test "http error if all is given", %{
      affiliate: affiliate,
      affiliate_user: %{user: user},
      event: event
    } do
      assert {:error, :econnrefused} = Affiliate.Public.send_event(affiliate, event, user)
    end
  end

  describe "obtain_user" do
    test "obtain non existing user" do
      affiliate = Factories.insert!(:affiliate)
      user = Affiliate.Public.obtain_user("test_user", affiliate)

      assert user.id != nil
    end

    test "obtain existing user" do
      affiliate = Factories.insert!(:affiliate)
      user = Factories.insert!(:affiliate_user, %{identifier: "test_user", affiliate: affiliate})
      user_2 = Affiliate.Public.obtain_user("test_user", affiliate)

      assert user.id == user_2.id
    end

    test "obtain existing user with the same identifier as another existingaffiliate user" do
      affiliate = Factories.insert!(:affiliate)
      affiliate2 = Factories.insert!(:affiliate)
      _user = Factories.insert!(:affiliate_user, %{identifier: "test_user", affiliate: affiliate})

      user_2_a =
        Factories.insert!(:affiliate_user, %{identifier: "test_user", affiliate: affiliate2})

      user_2_b = Affiliate.Public.obtain_user("test_user", affiliate2)

      assert user_2_a.id == user_2_b.id
    end
  end
end
