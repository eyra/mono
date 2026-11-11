# `Systems.Account.UserAuth`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/user_auth.ex#L1)

# `fetch_current_user`

Authenticates the user by looking into the session
and remember me token.

# `forget_user`

  Removes user token and cookie

# `log_in_user`

Logs the user in.

It renews the session ID and clears the whole session
to avoid fixation attacks. See the renew_session
function to customize this behaviour.

It also sets a `:live_socket_id` key in the session,
so LiveView sessions are identified and automatically
disconnected on log out. The line can be safely removed
if you are not using LiveView.

# `log_in_user_without_redirect`

Starts a session for the user like `log_in_user/4`, but leaves the
response to the caller. `params` selects the session type and the
remember-me cookie the same way.

# `log_out_user`

Logs the user out.

It clears all session data for safety. See renew_session.

# `redirect_if_user_is_authenticated`

Used for routes that require the user to not be authenticated.

# `require_authenticated_member`

Like `require_authenticated_user/2`, for pages participants open (tasks,
pool and lab pages). Signed-out visitors go to the SaaS's
`member_sign_in_page/1`.

# `require_authenticated_participant`

Like `require_authenticated_user/2`, but sends signed-out visitors to the
participant entry page with the requested path as `return_to`. Used for
assignment invitation links.

# `require_authenticated_user`

Used for routes that require the user to be authenticated.

If you want to enforce the user email is confirmed before
they use the application at all, here would be a good place.

# `sign_out_current_user`

Signs out the current user without redirecting.

Broadcasts a disconnect to any active LiveView session, forgets the
user (deletes token and remember-me cookie) and renews the session.

# `signed_in_path`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
