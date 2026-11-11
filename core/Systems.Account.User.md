# `Systems.Account.User`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/user.ex#L1)

The User module encapsulates the changesets for creating and updating users.

The logic for hashing passwords is also managed here. Bcrypt is used as
adviced by OWASP:

https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#password-hashing-algorithms

# `t`

```elixir
@type t() :: %Systems.Account.User{
  __meta__: Ecto.Schema.Metadata.t(),
  confirmed_at: NaiveDateTime.t() | nil,
  creator: boolean() | nil,
  displayname: String.t() | nil,
  email: String.t() | nil,
  features:
    Systems.Account.FeaturesModel.t() | Ecto.Association.NotLoaded.t() | nil,
  hashed_password: String.t() | nil,
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  merchant_uid: String.t() | nil,
  password: String.t() | nil,
  phone: String.t() | nil,
  profile:
    Systems.Account.UserProfileModel.t() | Ecto.Association.NotLoaded.t() | nil,
  updated_at: NaiveDateTime.t(),
  verified_at: NaiveDateTime.t() | nil,
  visited_pages: [String.t()] | nil
}
```

# `admin_changeset`

# `confirm_changeset`

Confirms the account by setting `confirmed_at`.

# `display_changeset`

A user changeset for changing the display name.

# `email_changeset`

A user changeset for changing the email.

It requires the email to change otherwise an error is added.

# `email_format`

# `email_max_length`

# `get_gender`

# `label`

# `new_session_changeset`

# `password_changeset`

A user changeset for changing the password.

## Options

  * `:hash_password` - Hashes the password so it can be stored securely
    in the database and ensures the password field is cleared to prevent
    leaks in the logs. If password hashing is not needed and clearing the
    password field is not desired (like when using this changeset for
    validations on a LiveView form), this option can be set to `false`.
    Defaults to `true`.

# `phone_changeset`

Changeset for the participant's phone number, collected in the payouts
("Uitbetalingen") flow and pushed to the payment provider so OPP no longer
redirects the participant to its hosted page to enter one. Normalizes to
E.164 (defaulting a bare Dutch number to +31) and validates the format.

# `registration_changeset`

A user changeset for registration.

It is important to validate the length of both email and password.
Otherwise databases may truncate the email without warnings, which
could lead to unpredictable or insecure behaviour. Long passwords may
also be very expensive to hash for certain algorithms.

## Options

  * `:hash_password` - Hashes the password so it can be stored securely
    in the database and ensures the password field is cleared to prevent
    leaks in the logs. If password hashing is not needed and clearing the
    password field is not desired (like when using this changeset for
    validations on a LiveView form), this option can be set to `false`.
    Defaults to `true`.

# `sso_changeset`

A user changeset for use with Single Sign On systems. It implicitly trusts
most data that it receives.

# `user_id`

# `user_profile_changeset`

User changeset for profile page

# `valid_email?`

# `valid_email_changeset`

# `valid_password?`

Verifies the password.

If there is no user or the user doesn't have a password, we call
`Bcrypt.no_user_verify/0` to avoid timing attacks.

# `validate_current_password`

Validates the current password otherwise adds an error to the changeset.

# `validate_email`

# `validate_password`

# `visited_changeset`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
