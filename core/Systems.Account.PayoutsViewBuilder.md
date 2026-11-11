# `Systems.Account.PayoutsViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/payouts_view_builder.ex#L1)

Builds the view model for the "Uitbetalingen" (payouts) tab:

  * `bank` — the bank-account verification status (a colored badge + an action
    button), derived live from OPP via `Fund.Public.verification_status/1`.
  * `overview` — the payout history grouped by year (`Fund.Public.list_payouts_for_user/1`),
    with a per-year total. The view picks the rows for the selected year.

All i18n lives here; `PayoutsView` only renders the supplied strings.

# `bank_verification_modal`

Confirmation modal for the "Toevoegen" action. Confirming hands the participant
off (`http_get`) to OPP's hosted verification page, where OPP's own iDEAL flow
lets them pick their bank — so we keep no bank list of our own.

# `phone_form_modal`

In-platform modal that collects the participant's phone number before handing
off to OPP's iDEAL bank verification. Pushing the phone via the API satisfies
OPP's compliance requirement so the participant is not redirected to OPP's
hosted merchant-overview page to enter one (see `Systems.Account.PhoneForm`).

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
