# `Systems.Admin.ActionsViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/actions_view_builder.ex#L1)

ViewBuilder for the Admin ActionsView.

Builds the view model for administrative actions like:
- Rolling back expired deposits
- Marking expired tasks
- Debug tools (crash button, force expire)

# `build_expire_force_button`

Builds the expire force button for debug mode.

This button is only shown when the :debug_expire_force feature flag is enabled.
Call this separately and include in the view when the flag is enabled.

# `view_model`

Builds the view model for the ActionsView.

The model parameter is unused but provided for consistency with the ViewBuilder pattern.
The assigns parameter is unused but available for future use (e.g., feature flags).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
