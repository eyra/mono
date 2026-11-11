# `Systems.Account.PhoneForm`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/phone_form.ex#L1)

In-platform modal that collects the participant's phone number for the payouts
("Uitbetalingen") flow.

On submit it persists the phone, pushes it to the payment provider (so OPP no
longer hosts a separate phone-entry page) and hands the participant off to
OPP's iDEAL bank verification — the single remaining OPP step. The redirect
explanation that used to live in its own confirmation modal is folded into this
form, so the participant fills in their number and continues straight to their
bank. Cancelling is handled by the modal chrome's close control.

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
