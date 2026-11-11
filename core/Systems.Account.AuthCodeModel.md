# `Systems.Account.AuthCodeModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth_code.ex#L1)

# `active_query`

# `attempt_query`

Selects the code only while it has attempts left. Run it with
`Repo.update_all(query, inc: [attempts: 1])`: the database checks the limit and
counts the attempt in one statement, so concurrent requests can't check a
code more often than `@max_attempts` times.

# `attempts_left?`

# `build`

# `expired_query`

# `matches?`

# `normalize_email`

The form of an email address used for codes and their request limit, so
every spelling of one address shares one code, one limit and one attempts
counter. `users.email` is citext, so user lookups already ignore case.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
