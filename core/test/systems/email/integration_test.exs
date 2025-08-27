defmodule Systems.Email.IntegrationTest do
  use ExUnit.Case, async: true

  alias Core.Factories
  alias Systems.Email.Factory

  describe "bamboo_phoenix 2.0 integration" do
    test "renders emails with layouts correctly" do
      user = Factories.build(:member)
      url = "https://example.com/confirm"
      email = Factory.account_confirmation_instructions(user, url)

      # Verify HTML body has layout elements
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "<style>"
      assert email.html_body =~ "body,h1,h2,h3,p,table,tr,td"

      # Verify content is inside layout
      assert email.html_body =~ "Activate your account"
      assert email.html_body =~ url

      # Verify text body has layout elements (simpler layout)
      assert email.text_body =~ "Activate your account"
      assert email.text_body =~ url
    end

    test "handles safe tuples from embedded templates correctly" do
      user = Factories.build(:member)
      email = Factory.account_created(user)

      # Should not have any safe tuple artifacts in output
      refute email.html_body =~ "{:safe"
      refute email.text_body =~ "{:safe"

      # Should be valid HTML string
      assert is_binary(email.html_body)
      assert is_binary(email.text_body)
    end

    test "notification email with custom HTML formatting" do
      title = "Test Notification"
      byline = "System | 2024-01-01"
      message = "First paragraph.\n\nSecond paragraph.\nWith a line break.\n\nThird paragraph."
      to = "user@example.com"

      email = Factory.notification(title, byline, message, to)

      # Verify HTML conversion (HTML is properly rendered, not escaped)
      assert email.html_body =~ "<p>First paragraph.</p>"
      assert email.html_body =~ "<p>Second paragraph.<br>With a line break.</p>"
      assert email.html_body =~ "<p>Third paragraph.</p>"

      # Verify text version preserves original
      assert email.text_body =~ "First paragraph."
      assert email.text_body =~ "Second paragraph.\nWith a line break."
      assert email.text_body =~ "Third paragraph."

      # Verify title and byline
      assert email.html_body =~ title
      assert email.html_body =~ byline
      assert email.text_body =~ title
      assert email.text_body =~ byline
    end

    test "debug email renders correctly with custom from address" do
      from_user = Factories.build(:member)
      to_user = Factories.build(:member)
      subject = "Debug Test"
      message = "This is a debug message"

      email = Factory.debug(subject, message, from_user, to_user)

      assert email.from == from_user.email
      assert email.to == to_user.email
      assert email.subject == subject
      assert email.html_body =~ message
      assert email.text_body =~ message
    end

    test "email with header image assignment renders correctly" do
      user = Factories.build(:member)
      email = Factory.account_created(user)

      # Verify the notification header image is in the HTML
      assert email.html_body =~ "email-header-notification"
      assert email.html_body =~ "srcset"

      # Header images should only be in HTML, not text
      refute email.text_body =~ "email-header-notification"
    end

    test "layout inner_content is properly embedded" do
      user = Factories.build(:member)
      url = "https://example.com/reset"
      email = Factory.reset_password_instructions(user, url)

      # The content should be within the layout structure
      # Check that layout wraps the content properly
      assert email.html_body =~ "<body>"
      assert email.html_body =~ "</body>"

      # Content should appear in the HTML body
      assert email.html_body =~ "New password"
      assert email.html_body =~ url
    end

    test "multiple recipients via mail_user" do
      emails = ["user1@example.com", "user2@example.com", "user3@example.com"]
      title = "Multi-recipient Test"
      byline = "Test"
      message = "Test message"

      email = Factory.notification(title, byline, message, emails)

      assert email.to == emails
      assert email.subject == "Next notification"
    end

    test "template and layout functions are called with correct format" do
      # This test verifies the new bamboo_phoenix 2.0 signature
      user = Factories.build(:member)
      url = "https://example.com"

      # Test all email types to ensure they work with new signature
      emails = [
        Factory.account_confirmation_instructions(user, url),
        Factory.reset_password_instructions(user, url),
        Factory.update_email_instructions(user, url),
        Factory.already_activated_notification(user, url),
        Factory.account_created(user)
      ]

      for email <- emails do
        # All should have both HTML and text bodies
        assert email.html_body != nil
        assert email.text_body != nil

        # Both should be strings (not safe tuples)
        assert is_binary(email.html_body)
        assert is_binary(email.text_body)

        # HTML should have HTML tags
        assert email.html_body =~ "<"
        assert email.html_body =~ ">"

        # Text should not have HTML tags
        refute email.text_body =~ "<html"
        refute email.text_body =~ "<body"
      end
    end
  end

  describe "email formatting consistency" do
    test "all emails have consistent structure" do
      user = Factories.build(:member)
      url = "https://example.com"

      emails = [
        Factory.account_confirmation_instructions(user, url),
        Factory.reset_password_instructions(user, url),
        Factory.update_email_instructions(user, url),
        Factory.already_activated_notification(user, url),
        Factory.account_created(user)
      ]

      for email <- emails do
        # All HTML emails should have the standard layout elements
        assert email.html_body =~ "<!DOCTYPE html>"
        assert email.html_body =~ "<style>"
        assert email.html_body =~ "background-color: #F6F6F6"
        assert email.html_body =~ "background-color: #FFFFFF"

        # Footer should be consistent
        assert email.html_body =~ "footer"

        # All should have proper email structure
        assert email.to == user.email
        assert email.subject != nil
        assert email.subject != ""
      end
    end

    test "HTML emails handle special characters properly" do
      user = Factories.build(:member)
      url = "https://example.com/path?param=value"

      email = Factory.update_email_instructions(user, url)

      # URL should maintain its structure in HTML
      assert email.html_body =~ url

      # Displayname should appear in both HTML and text
      assert email.html_body =~ user.displayname
      assert email.text_body =~ user.displayname
    end
  end
end
