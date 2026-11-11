# `Systems.Account.UserTokenModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/user_token.ex#L1)

# `build_email_token`

Builds a token with a hashed counter part.

The non-hashed token is sent to the user email while the
hashed part is stored in the database, to avoid reconstruction.
The token is valid for a week as long as users don't change
their email.

# `build_one_time_token`

Builds a token for a one-time step of `context`, such as handing a sign-in
over to another client. Like an email token, only its hash is stored.

# `build_session_token`

# `build_session_token`

Generates a token that will be stored in a signed place,
such as session or cookie. As they are signed, those
tokens do not need to be hashed.

# `one_time_token_query`

The token of `context` that was built less than `max_age` seconds ago, or
`:error` for a token that is not valid Base64.

# `session_token_query`

# `token_and_context_query`

Returns the given token with the given context.

# `touch_mobile_session_token`

# `user_and_contexts_query`

Gets all tokens for the given user for the given contexts.

# `verify_change_email_token_query`

Checks if the token is valid and returns its underlying lookup query.

The query returns the user token record.

# `verify_email_token_query`

Checks if the token is valid and returns its underlying lookup query.

The query returns the user found by the token.

# `verify_session_token_query`

Checks if the token is valid and returns its underlying lookup query.

The query returns the user found by the token.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
