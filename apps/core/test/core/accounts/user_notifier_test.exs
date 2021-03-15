defmodule Core.Accounts.UserNotifier.Test do
  use ExUnit.Case, async: true
  use Bamboo.Test

  alias Core.Factories
  alias Core.Accounts.UserNotifier

  describe("deliver_confirmation_instructions/2") do
    test "mail is delivered" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      {:ok, _} = UserNotifier.deliver_confirmation_instructions(user, url)
      assert_email_delivered_with(subject: "Confirm your account")
    end
  end

  describe("deliver_reset_password_instructions/2") do
    test "mail is delivered" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      {:ok, _} = UserNotifier.deliver_reset_password_instructions(user, url)
      assert_email_delivered_with(subject: "Password reset")
    end
  end

  describe("deliver_update_email_instructions/2") do
    test "mail is delivered" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      {:ok, _} = UserNotifier.deliver_update_email_instructions(user, url)
      assert_email_delivered_with(subject: "Update email")
    end
  end

  describe("deliver_already_activated_notification/2") do
    test "mail is delivered" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      {:ok, _} = UserNotifier.deliver_already_activated_notification(user, url)
      assert_email_delivered_with(subject: "Already activated")
    end
  end
end
