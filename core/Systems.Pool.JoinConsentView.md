# `Systems.Pool.JoinConsentView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/join_consent_view.ex#L1)

Informed-consent view for joining a pool.

Renders a short "would you like to join this pool?" prompt with an
Accept action. Publishes `:accept` on click; the parent handles the
actual join and container UI (advance the onboarding step, close a
modal, ...).

No explicit decline action — users hit browser Back to exit, same
convention as the auth identify/verify pages. Soft consent only —
no signed record is created. If the pool ever needs a proper signed
agreement, wrap `Systems.Consent.ClickWrapView` instead.

# `add_child`

# `async`

# `auth_module`

# `compose`

# `compose_child`

# `compose_element`

# `flash_error`

# `flash_error`

# `flash_info`

# `flash_persister_error`

# `flash_persister_error`

# `flash_persister_saved`

# `handle_info`

# `hide_flash`

# `print_auth_roles`

# `reset_fabric`

# `save`

# `save_closure`

# `update_child`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
