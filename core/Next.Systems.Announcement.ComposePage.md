# `Next.Systems.Announcement.ComposePage`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/compose_page.ex#L1)

The page to compose an announcement: `/admin/announcement/new` for a new one,
`/admin/announcement/:id` to open one from the list on the Admin page.
Saving stores the announcement unpublished. Publishing sends it to the
audience chosen below the form: creators, narrowed by the Admin → Users
filters and search. The server resolves the audience itself
(`Next.Systems.Announcement.Public.publish_announcement/4`). Saved,
published or cancelled, it goes back to the list.

A published announcement opens with only its title, summary and body:
saving shows the changes to its recipients without sending it again
(`Next.Systems.Announcement.Public.update_announcement/2`).

Only system admins open it, and only while the `announcements` flag is on;
every event checks both again.

# `auth_module`

# `handle_close_modal`

# `handle_consumed_event`

# `handle_hide_modal`

# `handle_present_modal`

# `handle_resize`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `print_auth_roles`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_actions`

# `update_menus`

# `update_menus`

# `update_view_model`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
