defmodule Systems.Email.EmailHTML do
  use Phoenix.Component

  # Embed templates first so they're available as functions
  embed_templates("email/*.html", suffix: "_html")
  embed_templates("email/*.text", suffix: "_text")

  # bamboo_phoenix 2.0 expects the template function to return a plain string
  # or a Phoenix.HTML safe tuple. It flattens safe iodata with Enum.map, which
  # crashes on the improper lists Phoenix.HTML.Safe emits when escaping
  # apostrophes (`[<<...>> | "&#39;"]`). Convert to binary here so bamboo
  # hits its `is_binary/1` clause and skips the broken flatten path.
  defp to_binary({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp to_binary(binary) when is_binary(binary), do: binary

  # Define template functions for bamboo_phoenix 2.0
  # Each function takes format ("html" or "text") as first arg and assigns as second
  def otp_sign_in("html", assigns), do: assigns |> otp_sign_in_html() |> to_binary()
  def otp_sign_in("text", assigns), do: assigns |> otp_sign_in_text() |> to_binary()

  def account_confirmation_instructions("html", assigns),
    do: assigns |> account_confirmation_instructions_html() |> to_binary()

  def account_confirmation_instructions("text", assigns),
    do: assigns |> account_confirmation_instructions_text() |> to_binary()

  def account_created("html", assigns), do: assigns |> account_created_html() |> to_binary()
  def account_created("text", assigns), do: assigns |> account_created_text() |> to_binary()

  def already_activated_notification("html", assigns),
    do: assigns |> already_activated_notification_html() |> to_binary()

  def already_activated_notification("text", assigns),
    do: assigns |> already_activated_notification_text() |> to_binary()

  def debug_message("html", assigns), do: assigns |> debug_message_html() |> to_binary()
  def debug_message("text", assigns), do: assigns |> debug_message_text() |> to_binary()

  def notification("html", assigns), do: assigns |> notification_html() |> to_binary()
  def notification("text", assigns), do: assigns |> notification_text() |> to_binary()

  def reset_password_instructions("html", assigns),
    do: assigns |> reset_password_instructions_html() |> to_binary()

  def reset_password_instructions("text", assigns),
    do: assigns |> reset_password_instructions_text() |> to_binary()

  def update_email_instructions("html", assigns),
    do: assigns |> update_email_instructions_html() |> to_binary()

  def update_email_instructions("text", assigns),
    do: assigns |> update_email_instructions_text() |> to_binary()

  def contribution_accepted("html", assigns),
    do: assigns |> contribution_accepted_html() |> to_binary()

  def contribution_accepted("text", assigns),
    do: assigns |> contribution_accepted_text() |> to_binary()

  def contribution_declined("html", assigns),
    do: assigns |> contribution_declined_html() |> to_binary()

  def contribution_declined("text", assigns),
    do: assigns |> contribution_declined_text() |> to_binary()
end
