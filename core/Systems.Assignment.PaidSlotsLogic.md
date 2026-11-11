# `Systems.Assignment.PaidSlotsLogic`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/paid_slots_logic.ex#L1)

Paid-slots concerns mixed into the parent LiveComponent (typically
ParticipantsView):

  * `use` injects the LiveComponent callbacks
    (`compose(:pay_in_request_form, …)` and the paid-slots
    `handle_event/3` clauses) so the parent gets the modal lifecycle
    and payment-resume flow for free.
  * Public helpers (`assign_paid_slots_state/1`, `list_transactions/1`,
    `format_cents/1`, etc.) are called directly from the parent's
    `update/2` and render.

All state lives on the parent component's socket; this module owns
none.

# `active_currency`

# `assign_active_currency`

# `assign_add_button`

# `assign_paid_slots_state`

# `assign_transactions`

# `budget_description`

# `format_cents`

# `list_transactions`

# `refresh_assignment`

# `status_tag`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
