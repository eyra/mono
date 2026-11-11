# `Systems.Pool.OnboardingPage`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/onboarding_page.ex#L1)

Pool-scoped onboarding at `/pool/:slug/onboarding`.

Reached through `Systems.Pool.Controller.join/2`, which acts as the
gate: it resolves the slug and checks participation before forwarding
here. This page trusts that gate — it does not re-check participation
and does not redirect from `mount/3`. An invalid slug crashes with
`Ecto.NoResultsError`, which Phoenix renders as 404.

Mirrors `Systems.Account.OnboardingPage`: a builder produces the
ordered `:steps` and the current step's `step_view` element (plus an
optional page-level continue button); the page renders them via
`<.element>` and progresses either via `consume_event` (for steps
whose view publishes events, like `:join_consent`) or `handle_event`
(for steps advanced by the continue button, like `:features`).

Steps:

  * `:join_consent` — `Pool.JoinConsentView` publishes `:accept`.
    Accept adds the user as a participant and advances to `:features`.
    There is no decline action — users hit browser Back to exit.
  * `:features` — `Account.FeaturesView` (embedded LiveView) captures
    gender / birth year. A page-level continue button advances.
  * `:already_member` — static info block; no interaction.

# `auth_module`

# `handle_close_modal`

# `handle_consumed_event`

# `handle_hide_modal`

# `handle_info`

# `handle_present_modal`

# `handle_resize`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `print_auth_roles`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_actions`

# `update_menus`

# `update_menus`

# `update_view_model`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
