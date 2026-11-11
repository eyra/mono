# `Systems.Assignment.DeclineContributionForm`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/decline_contribution_form.ex#L1)

Modal-hosted form for declining a single pending contribution. Presented via
`LiveNest.Modal.prepare_live_component/3` from `Systems.Assignment.ContributionsView`.

Requires a reason and a confirmation input where the researcher retypes the
subject label (e.g. "Participant 2") — mirrors the safety pattern in
`Systems.Storage.EmptyConfirmationView`. Rather than disabling the Decline
button, the form runs a schemaless changeset on submit and lets the pixel
`.text_area` / `.text_input` components surface the errors via their
built-in error slot. `data-show-errors` on the form gates whether errors
render, so the first render is clean until the researcher tries to submit
an invalid form.

On submit the form sends `{:submit_decline, %{participation_id, reason}}` to the
parent LV process (`ContributionsView`) which runs the actual mutation.

# `add_child`

# `async`

# `auth_module`

# `compose`

# `compose_child`

# `compose_element`

# `handle_info`

# `print_auth_roles`

# `reset_fabric`

# `update_child`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
