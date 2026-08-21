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
  def otp_sign_in("html", assigns), do: otp_sign_in_html(assigns) |> to_binary()
  def otp_sign_in("text", assigns), do: otp_sign_in_text(assigns) |> to_binary()

  def account_confirmation_instructions("html", assigns),
    do: account_confirmation_instructions_html(assigns) |> to_binary()

  def account_confirmation_instructions("text", assigns),
    do: account_confirmation_instructions_text(assigns) |> to_binary()

  def account_created("html", assigns), do: account_created_html(assigns) |> to_binary()
  def account_created("text", assigns), do: account_created_text(assigns) |> to_binary()

  def already_activated_notification("html", assigns),
    do: already_activated_notification_html(assigns) |> to_binary()

  def already_activated_notification("text", assigns),
    do: already_activated_notification_text(assigns) |> to_binary()

  def debug_message("html", assigns), do: debug_message_html(assigns) |> to_binary()
  def debug_message("text", assigns), do: debug_message_text(assigns) |> to_binary()

  def notification("html", assigns), do: notification_html(assigns) |> to_binary()
  def notification("text", assigns), do: notification_text(assigns) |> to_binary()

  def reset_password_instructions("html", assigns),
    do: reset_password_instructions_html(assigns) |> to_binary()

  def reset_password_instructions("text", assigns),
    do: reset_password_instructions_text(assigns) |> to_binary()

  def update_email_instructions("html", assigns),
    do: update_email_instructions_html(assigns) |> to_binary()

  def update_email_instructions("text", assigns),
    do: update_email_instructions_text(assigns) |> to_binary()

  def contribution_accepted("html", assigns),
    do: contribution_accepted_html(assigns) |> to_binary()

  def contribution_accepted("text", assigns),
    do: contribution_accepted_text(assigns) |> to_binary()

  def contribution_declined("html", assigns),
    do: contribution_declined_html(assigns) |> to_binary()

  def contribution_declined("text", assigns),
    do: contribution_declined_text(assigns) |> to_binary()
end
