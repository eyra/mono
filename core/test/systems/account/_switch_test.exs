defmodule Systems.Account.SwitchTest do
  use ExUnit.Case, async: true
  use Bamboo.Test
  alias Core.Factories
  alias Systems.Account

  describe "user_created" do
    test "sends mail" do
      user = Factories.build(:member)
      Account.Switch.intercept({:user, :created}, %{user: user})
      assert_email_delivered_with(subject: "Welcome")
    end
  end
end
