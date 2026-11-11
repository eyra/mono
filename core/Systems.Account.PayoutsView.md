# `Systems.Account.PayoutsView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/payouts_view.ex#L1)

Embedded LiveView for the "Uitbetalingen" (payouts) tab.

Shows the participant's bank-account verification status and payout history:

  * Bankrekening — a colored status badge (`:not_verified` red, `:pending`
    orange, `:verified` green) plus an action button. "Toevoegen" first opens
    an in-platform phone form (`Systems.Account.PhoneForm`) when no phone is
    known — pushing it to OPP via the API avoids a hosted phone-entry redirect.
    With a phone already on file it runs `Fund.Public.start_bank_verification/1`
    and opens a confirmation modal. Either way the participant ends up at OPP's
    hosted iDEAL flow, where OPP lets them pick their bank (we keep no bank list
    of our own).

  * Overzicht — payout history (`Fund.Public.list_payouts_for_user/1`) grouped
    by year, with a year filter and a per-year total.

The `:pending` badge flips to `:verified` reactively: an OPP `bank_account`
webhook dispatches `{:payment_kyc, :updated}` which the Observatory broadcast
re-renders this view (see `Systems.Account.Switch`). A slow poll while pending
is the fallback for missed webhooks.

# `consume_event`

# `dependencies`

# `get_model`

# `handle_consumed_event`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
