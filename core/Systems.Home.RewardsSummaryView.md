# `Systems.Home.RewardsSummaryView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/home/rewards_summary_view.ex#L1)

"Vergoedingen" card on the participant home page. Three columns — pending,
approved, rejected — each showing the per-status amount (cents) and a label.

The approved column also exposes a "Uitbetalen" (payout) button when the
participant has any `:approved` rewards. Clicking it runs
`Fund.Public.prepare_payout/1` and presents the MS.6 handoff via the shared
`Frameworks.Pixel.ConfirmationModal` (`show_modal(:handoff_modal, :compact)`):

  * `:ok` — `:payout` variant ("you are leaving Next to be sent to OPP");
    confirming fires `Fund.Public.request_payout/1`.
  * `{:kyc_required, _, _}` — `:verify` variant; the bank account isn't
    verified yet, so an info modal lets the participant close it or continue to
    the account page (`/user/account?tab=payouts`), where verification lives.
  * `{:below_threshold, _}` — a flash, no modal.
  * any other error — `:verify` variant too: the payouts tab is the only
    actionable next step, so never dead-end on "try again later".

Errors from `Fund.Public.request_payout/2` — after confirming, and on retry —
are routed the same way: threshold misses flash, anything else swaps the modal
to the `:verify` variant rather than a generic "try again later".

All i18n is resolved by `Systems.Home.PageBuilder`; this view only renders
the supplied `labels`.

# `add_child`

# `async`

# `auth_module`

# `compose_child`

# `compose_element`

# `handle_info`

# `print_auth_roles`

# `reset_fabric`

# `update_child`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
