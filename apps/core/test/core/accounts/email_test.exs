defmodule Core.Accounts.Email.Test do
  use ExUnit.Case, async: true

  alias Core.Factories
  alias Core.Accounts.Email

  describe("account_confirmation_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Email.account_confirmation_instructions(user, url)
      assert email.to == user.email
      assert email.subject == "Confirm your account"
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("reset_password_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Email.reset_password_instructions(user, url)
      assert email.to == user.email
      assert email.subject == "Password reset"
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("update_email_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Email.update_email_instructions(user, url)
      assert email.to == user.email
      assert email.subject == "Update email"
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("already_activated_notification/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Email.already_activated_notification(user, url)
      assert email.to == user.email
      assert email.subject == "Already activated"
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end
end
