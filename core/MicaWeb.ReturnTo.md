# `MicaWeb.ReturnTo`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/return_to.ex#L1)

Same-origin `return_to` handling shared across auth, onboarding, and
pool-join flows.

  * `sanitize/1` — accept only same-site paths: a single leading `/`,
    not followed by another `/` or a `\`, and no control characters.
    Everything else becomes `nil`, so the flow falls back to its
    default destination.
  * `append/2` — URL-encode and attach a `return_to=<path>` query
    param to a URL, picking `?` or `&` based on whether the target
    already has a query string. `nil` is a no-op.
  * `resolve/2` — pick `return_to` when present, otherwise fall back
    to the caller-provided default. Convenient at "flow finish" call
    sites that would otherwise write `return_to || default`.

# `append`

# `resolve`

# `sanitize`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
