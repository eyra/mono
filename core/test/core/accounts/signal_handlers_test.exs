defmodule Core.Accounts.SignalHandlersTest do
  use ExUnit.Case, async: true
  use Bamboo.Test
  alias Core.Factories
  alias Core.Accounts.SignalHandlers

  describe "user_created" do
    test "sends mail" do
      user = Factories.build(:member)
      SignalHandlers.intercept({:user, :created}, %{user: user})
      assert_email_delivered_with(subject: "Welcome")
    end
  end
end
