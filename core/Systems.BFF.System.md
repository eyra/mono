# `Systems.BFF.System`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/_system.ex#L1)

The backend for frontend (BFF) of the native apps: `GET /bff/page/:page`
answers `{"blocks": [...]}` for a page of the mica-bff spec. Systems serve the
pages through `c:Mica.System.bff_pages/0`; the blocks are the generated
`Systems.BFF.Blocks.*` modules. The app sends the spec version it implements in
the `x-bff-spec` header, which is only recorded for now.

# `account_tabs`

# `admin_panels`

# `bff_pages`

# `children`

# `desktop_sections`

# `feature_flags`

# `grants`

# `migrations_path`

# `notifiers`

# `notify_channels`

# `oban_crons`

# `oban_queues`

# `override_routes`

# `rate_quotas`

# `routes`

# `seeds`

# `sign_in_handoffs`

# `signal_handlers`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
