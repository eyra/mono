# `Systems.Account.Auth.SSOHelpers`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/sso_helpers.ex#L1)

Shared helpers for SSO registration across different providers.

Handles common error scenarios like duplicate emails gracefully,
extracting errors from nested changesets and providing consistent
error handling across Surfconext, Google Sign In, Sign In with Apple, etc.

# `collect_errors`

Collects all errors from a changeset, including nested changesets.

Extracts errors from both the parent changeset and any nested `:user` changeset,
which is common in SSO registration where the SSO user wraps an Account.User.

# `error_message`

Returns a user-friendly error message for predefined error codes.

Used for SSO-related errors that occur before changeset validation,
such as missing authentication state.

# `handle_registration_error`

Handles SSO registration result, redirecting to signin with error flash on failure.

For successful registration, calls the success callback.
For failed registration, extracts all errors (including nested changeset errors)
and redirects to the signin page with error messages.

## Examples

    # In a callback plug:
    case MySSO.register_user(user_info) do
      {:ok, sso_user} ->
        log_in_user(config, conn, sso_user.user, true)

      {:error, changeset} ->
        Systems.Account.Auth.SSOHelpers.handle_registration_error(conn, changeset)
    end

# `handle_registration_error`

Like `handle_registration_error/2` for a sign-in through `provider`, which a
`Systems.Account.SignInHandoff` may end instead.

# `redirect_with_error`

Ends a failed sign-in through `provider` on the sign-in page with the message
of `error` (see `error_message/1`), unless a `Systems.Account.SignInHandoff`
ends it.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
