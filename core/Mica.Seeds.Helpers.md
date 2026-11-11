# `Mica.Seeds.Helpers`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/helpers.ex#L1)

Generic helpers for idempotent seed operations.

Use these from environment-specific seed modules (`Mica.Seeds.Local`,
`Mica.Seeds.Dev`, `Mica.Seeds.Test`, etc.) to keep get-or-create logic
in one place.

# `ensure_user!`

Returns the existing user with the given email or inserts a confirmed user.

Accepts `:name` (used for both `displayname` and the profile `fullname`),
`:creator` (boolean, default false) and `:password` (required when
inserting). Existing users are returned untouched — the function is
idempotent and never overwrites attributes.

# `seed_creator!`

Idempotently seeds a creator account. Thin wrapper over
`ensure_user!/2` that forces `creator: true`. Use across deploy
environments that need a known researcher account (local, dev,
test, staging).

Accepts the same options as `ensure_user!/2` — `:name` and
`:password` are required.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
