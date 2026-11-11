# `Systems.Account.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/_public.ex#L1)

# `activated?`

# `admin_update_user`

Saves an admin's change to a user (creator, verified, activated) and signals
`{:user, :update_and_dispatch}`, so views that show the user update.

# `affiliate?`

# `apply_user_email`

Emulates that the email will change without actually changing
it in the database.

## Examples

    iex> apply_user_email(user, "valid password", %{email: ...})
    {:ok, %User{}}

    iex> apply_user_email(user, "invalid password", %{email: ...})
    {:error, %Ecto.Changeset{}}

# `auth_module`

# `change_user_email`

Returns an `%Ecto.Changeset{}` for changing the user email.

## Examples

    iex> change_user_email(user)
    %Ecto.Changeset{data: %User{}}

# `change_user_password`

Returns an `%Ecto.Changeset{}` for changing the user password.

## Examples

    iex> change_user_password(user)
    %Ecto.Changeset{data: %User{}}

# `change_user_registration`

Returns an `%Ecto.Changeset{}` for tracking user changes.

## Examples

    iex> change_user_registration(user)
    %Ecto.Changeset{data: %User{}}

# `cleanup_expired_auth_codes`

Deletes auth codes that are past their validity window.

Codes older than the validity window can no longer satisfy `active_query/1`,
so the rows are dead weight. Returns the number of rows deleted.

# `confirm_user`

Confirms a user by the given token.

If the token matches, the user account is marked as confirmed
and the token is deleted.

# `confirmed?`

# `create_profile!`

# `delete_session_token`

Deletes the signed session token.

# `deliver_already_activated_notification`

# `deliver_update_email_instructions`

Delivers the update email instructions to the given user.

## Examples

    iex> deliver_update_email_instructions(user, current_email, &url(conn, ~p"/user/update-email/#{&1}"
    {:ok, %{to: ..., body: ...}}

# `deliver_user_confirmation_instructions`

Delivers the confirmation email instructions to the given user.

## Examples

    iex> deliver_user_confirmation_instructions(user, &url(conn, ~p"/user/settings/activate-account/#{&1}"))
    {:ok, %{to: ..., body: ...}}

    iex> deliver_user_confirmation_instructions(confirmed_user, &url(conn, ~p"/user/settings/activate-account/#{&1}"))
    {:error, :already_confirmed}

# `deliver_user_reset_password_instructions`

Delivers the reset password email to the given user.

## Examples

    iex> deliver_user_reset_password_instructions(user, &url(conn, ~p"/user/reset-password/#{&1}))
    {:ok, %{to: ..., body: ...}}

# `external?`

# `generate_one_time_token`

Generates a token for a one-time step of `context`, replacing the user's
earlier token of that context. Redeem it with `take_one_time_token/3`.

# `generate_otp`

Emails a new sign-in code to `email`, replacing any earlier code for it.
`remote_ip` is the client's address (`MicaWeb.Plug.RemoteIp`), which the
limits of `Account.AuthCodeLimits` count by.

# `generate_user_session_token`

Generates a session token.

# `get!`

# `get_display_label`

# `get_features`

# `get_profile`

# `get_user!`

Gets a single user.

Raises `Ecto.NoResultsError` if the User does not exist.

## Examples

    iex> get_user!(123)
    %User{}

    iex> get_user!(456)
    ** (Ecto.NoResultsError)

# `get_user_by_email`

Gets a user by email.

## Examples

    iex> get_user_by_email("foo@example.com")
    %User{}

    iex> get_user_by_email("unknown@example.com")
    nil

# `get_user_by_email_and_password`

Gets a user by email and password.

## Examples

    iex> get_user_by_email_and_password("foo@example.com", "correct_password")
    %User{}

    iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
    nil

# `get_user_by_merchant_uid`

Gets the user linked to an OPP merchant, or nil. Used by the payment webhook to
route a bank-account/merchant KYC change back to the owning participant.

# `get_user_by_reset_password_token`

Gets the user by reset password token.

## Examples

    iex> get_user_by_reset_password_token("validtoken")
    %User{}

    iex> get_user_by_reset_password_token("invalidtoken")
    nil

# `get_user_by_session_token`

Gets the user with the given signed token.

# `internal?`

# `list_affiliate_users`

# `list_creators`

# `list_external_users`

# `list_internal_users`

# `list_pool_admins`

# `list_users`

# `mark_as_visited`

# `passwordless?`

# `print_auth_roles`

# `reconcile_orphaned_merchants`

Flags provider merchants that no user carries.
See `Systems.Account.MerchantOrphanReconciliation`.

# `register_user`

Registers a user.

## Examples

    iex> register_user(%{field: value})
    {:ok, %User{}}

    iex> register_user(%{field: bad_value})
    {:error, %Ecto.Changeset{}}

# `register_user_with_email`

Registers a new user from just an email (OTP-only auth flow). Creates a
passwordless account (`hashed_password: "no-password-set"`) with email
ownership marked as verified (the OTP code itself proves possession of
the inbox). The account stays unconfirmed until the user accepts terms
& privacy in the onboarding step.

# `register_via_sso`

Registers a new user from an SSO-provided attrs map. The IdP (SURFconext,
Google, …) has already proven email ownership, so the account is created
with `confirmed_at`/`verified_at` set by the caller's attrs and is
immediately usable. Dispatches `{:user, :created}`.

`attrs` is the flat normalized map produced by a `Systems.Account.Auth.Provider`'s
`user_attrs/1` callback — the User vs Profile schema split is an internal
concern handled here, not something the IdP has to know about. See
`Systems.Account.Auth.Provider.user_attrs/0` for the allowed keys.

# `renew_mobile_session_token`

Records authenticated activity for a valid mobile session.

# `reset_user_password`

Resets the user password.

## Examples

    iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
    {:ok, %User{}}

    iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
    {:error, %Ecto.Changeset{}}

# `search`

# `show_profile_menu_item?`

# `start_page_path`

# `start_page_title`

# `take_one_time_token`

Redeems a token of `generate_one_time_token/2` that is younger than `max_age`
seconds. Deleting the token is what makes it single-use: only the call that
deletes it gets the user.

# `update_features`

# `update_phone`

Persists the participant's phone number (payouts flow). Returns
`{:ok, user}` or `{:error, changeset}`.

# `update_user`

# `update_user_email`

Updates the user email using the given token.

If the token matches, the user email is updated and the token is deleted.
The confirmed_at date is also updated to the current time.

# `update_user_password`

Updates the user password.

## Examples

    iex> update_user_password(user, "valid password", %{password: ...})
    {:ok, %User{}}

    iex> update_user_password(user, "invalid password", %{password: ...})
    {:error, %Ecto.Changeset{}}

# `update_user_profile`

# `verify_otp`

Checks `code` against the active sign-in code of `email`. When a limit of
`Account.AuthCodeLimits` refuses the check, the result is
`{:error, :max_attempts}` and the code's own attempts stay unused.

# `visited?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
