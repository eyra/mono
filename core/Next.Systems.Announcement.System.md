# `Next.Systems.Announcement.System`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/_system.ex#L1)

Announcements that system admins write for creators, such as release notes:
the announcement, its rich-text body and the users who received it.

Everything users see of announcements (the announcement page, the Admin tab,
To-dos, email and the Desktop section) checks `feature_enabled?(:announcements)`
first. The flag is off by default (`Next.SaaS.feature_flags/0`).

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
