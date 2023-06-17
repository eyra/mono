defmodule Systems.Email.Factory.Test do
  use ExUnit.Case, async: true

  alias Core.Factories
  alias Systems.Email.Factory

  describe("account_confirmation_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Factory.account_confirmation_instructions(user, url)
      assert email.to == user.email
      assert email.subject == "Activate your account"
      assert email.html_body =~ "Activate your account"
      assert email.text_body =~ "Activate your account"
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("reset_password_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Factory.reset_password_instructions(user, url)
      assert email.to == user.email
      assert email.subject == "Password reset"
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("update_email_instructions/2") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      url = Faker.Internet.url()
      email = Factory.update_email_instructions(user, url)
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
      email = Factory.already_activated_notification(user, url)
      assert email.to == user.email
      assert email.subject == "Already activated"
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
      assert email.html_body =~ url
      assert email.text_body =~ url
    end
  end

  describe("account_created/1") do
    test "has all the fields filled properly" do
      user = Factories.build(:member)
      email = Factory.account_created(user)
      assert email.to == user.email
      assert email.subject =~ "Welcome"
      assert email.html_body =~ "You are all set and ready to use the platform"
      assert email.html_body =~ "email-header-welcome.png"
      assert email.text_body =~ "You are all set and ready to use the platform"
    end
  end
end
