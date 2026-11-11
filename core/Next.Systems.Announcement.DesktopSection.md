# `Next.Systems.Announcement.DesktopSection`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/desktop_section.ex#L1)

The Announcements section on Desktop, above Recent items: the newest
announcements the user received, read and unread, as cards that each open
the announcement page. Hidden while
the `:announcements` flag is off and for users without announcements.

It refreshes with Desktop: on `{:next_action, :cleared}` when an announcement
is opened (`Systems.Desktop.Switch`) and on `{:announcement, :updated}`
(`Next.Systems.Announcement.Switch`).

# `auth_module`

# `handle_info`

# `print_auth_roles`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
