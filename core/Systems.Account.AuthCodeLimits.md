# `Systems.Account.AuthCodeLimits`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth_code_limits.ex#L1)

Limits on sign-in codes on top of the checks each single code allows
(`Systems.Account.AuthCodeModel`). They count per email address, per email
address and network address together, and per network address, in the
database (`Rate.Public.increment_counter/2`), so all nodes share them and
restarts don't reset them. Windows are fixed: a refused address or network
is allowed again when the window ends.

The default limits:
- Requesting a code: 10 per email address and network address per hour,
  50 per email address per day, 200 per network address per hour.
- Checking a code: 10 per email address and network address per hour and
  30 per day, 100 per email address per day, 200 per network address per
  hour. Only checks of a code with attempts left count.
- While an email address can't check codes from a network address, it can't
  request new ones from there either; at its daily total of checks, from
  nowhere.

Counting an email address per network address means requests from one
network address can't use up the limits of the same email address on
another; the limits per email address alone bound the total across all
network addresses.

The totals per email address count last, after every other limit has
passed: only requests that send a code and checks that compare a code count
toward them, so events another limit refuses don't use them up.

An IPv6 client counts by its /64 network, which one connection usually owns
as a whole. The network address limits leave room for many people behind
one address, such as a university network or a mobile carrier.

The `AUTH_CODE_LIMITS` environment variable replaces the default limit of
each action, count and window it lists (`overrides!/1`); the other limits
keep their defaults. A window without a default adds a limit. A default
limit can be raised but not removed.

# `allow_check?`

Counts a check of a code for `email` (normalised) from `remote_ip` against
the limits per network address; false when one refuses it. The totals per
email address count separately, with `count_check?/1`.

# `allow_request?`

Counts a code request for `email` (normalised) from `remote_ip` against the
limits per network address (`email_network` and `network`); false when one
refuses it. The totals per email address count separately, with
`count_request?/1`, once every other limit has passed.

# `count_check?`

Counts a check of a code for `email` (normalised) against the totals per
email address; false when one refuses it. When the check then turns out not
to reach the code, because the code has no attempts left, `uncount_check/1`
takes it back, so the totals only count checks that compare a code.

# `count_request?`

Counts a code request for `email` (normalised) against the totals per email
address; false when one refuses it. Call it last, right before the code is
sent, so only requests that send a code count.

# `limits`

The limits in force: the defaults, of which the configured overrides
(`config :mica, :auth_code_limits, overrides: …`) replace the one with the
same action, count and window.

# `network`

The network address `remote_ip` counts by: an IPv4 address as is, an IPv6
address by its /64 prefix.

# `overrides!`

Parses the decoded JSON of `AUTH_CODE_LIMITS`, a list of limits such as
`{"action": "check", "by": "email", "limit": 20, "window": "hour"}`:
`action` is `request` or `check`, `by` is `email`, `email_network` or
`network`, `window` is `minute`, `hour` or `day`, and `limit` is a positive
integer. Raises on an invalid entry, and on an action, count and window
listed more than once.

# `uncount_check`

Takes back a check that `count_check?/1` counted.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
