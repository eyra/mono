# `Systems.Account.Auth.Email`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/email.ex#L1)

Email-first signup identity provider.

Creates a provisional Account.User (no password, not confirmed) plus a
satellite `Systems.Account.Auth.Email.UserModel` record with the UserCheck validation
result. Mirrors the Systems.Account.Auth.Google / Systems.Account.Auth.Apple / Surfconext pattern.

The satellite row persists as a historical breadcrumb even after the user
activates their account via another identity provider or by setting a
password.

## Usage

    case Systems.Account.Auth.Email.register("user@example.com") do
      {:ok, user} -> # Account.User created + satellite stored
      {:error, :already_registered} -> # email exists in users table
      {:error, :disposable} -> # rejected by policy
      {:error, :invalid_format} -> # not a valid email
    end

# `get_by_user`

Returns the Systems.Account.Auth.Email.UserModel satellite for a given user, or nil.

# `link`

Links a real email to an existing user (e.g. one created via Systems.Account.Auth.External
with a synthetic email).

1. Validates email format
2. Checks uniqueness
3. Calls UserCheck for validation (fails open on timeout/error)
4. Applies rejection policy
5. Updates user email + creates Systems.Account.Auth.Email.UserModel satellite

## Options

  * `:policy` - rejection policy module (default: `Systems.Account.Auth.Email.DefaultRejectionPolicy`)

# `opt_out`

Hard-deletes the user. Cascade deletes the satellite row.
Use for GDPR opt-out requests.

# `provisional?`

Returns true if the user is currently in a provisional state:
no real password set and not confirmed.

# `register`

Registers a user via email-first signup.

1. Validates email format
2. Checks uniqueness (returns `{:error, :already_registered}` if taken)
3. Calls UserCheck for validation (fails open on timeout/error)
4. Applies rejection policy
5. Creates Account.User + Systems.Account.Auth.Email.UserModel in a single transaction

## Options

  * `:policy` - rejection policy module (default: `Systems.Account.Auth.Email.DefaultRejectionPolicy`)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
