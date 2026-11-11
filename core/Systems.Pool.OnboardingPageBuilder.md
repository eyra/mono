# `Systems.Pool.OnboardingPageBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/onboarding_page_builder.ex#L1)

View model builder for `Systems.Pool.OnboardingPage`. Mirrors the shape
of `Systems.Account.OnboardingPageBuilder` for the page-owned parts
(steps + current step_view + optional info block + continue button),
so both pages can share render conventions.

The step list is participation-aware:

  * Non-participant → `[:join_consent, :features]` — first the
    consent screen (renders `Pool.JoinConsentView`), then the features
    form (renders `Account.FeaturesView`) to capture pool-relevant
    participant attributes like gender and birth year. Features used
    to live in the Account onboarding but is now pool-scoped, since
    it's only meaningful for someone who has just joined a pool.
  * Participant → `[:already_member]` — renders a static info
    block via `step_title` / `step_body`. No step_view is attached
    because there is nothing to interact with (yet — a leave-pool
    action is likely to be added here later).

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
