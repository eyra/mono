# `Systems.Email.Factory`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/email/factory.ex#L1)

# `account_confirmation_instructions`

# `account_created`

# `already_activated_notification`

# `contribution_accepted`

# `contribution_declined`

# `debug`

# `mail_user`

# `notification`

A notification with `title`, `byline` and the plain-text `message`.
Options: `subject` (default "Next notification") and `html_message`, the
HTML part (default: `message` as paragraphs).

# `otp_sign_in`

# `render`

Render an Phoenix template and set the body on the email.

Pass an atom as the template name (:welcome_email) to render HTML *and* plain
text emails. Use a string if you only want to render one type, e.g.
"welcome_email.text" or "welcome_email.html". Scroll to the top for more examples.

# `reset_password_instructions`

# `update_email_instructions`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
