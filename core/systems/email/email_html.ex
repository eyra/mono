defmodule Systems.Email.EmailHTML do
  use Phoenix.Component

  # Embed templates first so they're available as functions
  embed_templates("email/*.html", suffix: "_html")
  embed_templates("email/*.text", suffix: "_text")

  # Define template functions for bamboo_phoenix 2.0
  # Each function takes format ("html" or "text") as first arg and assigns as second
  # Returns whatever the embedded templates return (safe tuples for HTML, strings for text)
  # bamboo_phoenix will handle the normalization

  def account_confirmation_instructions("html", assigns) do
    account_confirmation_instructions_html(assigns)
  end

  def account_confirmation_instructions("text", assigns) do
    account_confirmation_instructions_text(assigns)
  end

  def account_created("html", assigns) do
    account_created_html(assigns)
  end

  def account_created("text", assigns) do
    account_created_text(assigns)
  end

  def already_activated_notification("html", assigns) do
    already_activated_notification_html(assigns)
  end

  def already_activated_notification("text", assigns) do
    already_activated_notification_text(assigns)
  end

  def debug_message("html", assigns) do
    debug_message_html(assigns)
  end

  def debug_message("text", assigns) do
    debug_message_text(assigns)
  end

  def notification("html", assigns) do
    notification_html(assigns)
  end

  def notification("text", assigns) do
    notification_text(assigns)
  end

  def new_notification("html", assigns) do
    new_notification_html(assigns)
  end

  def new_notification("text", assigns) do
    new_notification_text(assigns)
  end

  def reset_password_instructions("html", assigns) do
    reset_password_instructions_html(assigns)
  end

  def reset_password_instructions("text", assigns) do
    reset_password_instructions_text(assigns)
  end

  def update_email_instructions("html", assigns) do
    update_email_instructions_html(assigns)
  end

  def update_email_instructions("text", assigns) do
    update_email_instructions_text(assigns)
  end
end
