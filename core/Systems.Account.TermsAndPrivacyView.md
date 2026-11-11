# `Systems.Account.TermsAndPrivacyView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/terms_and_privacy_view.ex#L1)

Onboarding step shown to first-time SSO users: welcome + terms acceptance.
Embedded in OnboardingPage as the :terms_and_privacy step.

On continue with terms accepted: activates the user (sets confirmed_at)
and publishes :terms_completed for the parent to re-mount the onboarding
URL so the builder advances past this step.

# `consume_event`

# `dependencies`

# `get_model`

# `handle_consumed_event`

# `handle_info`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
