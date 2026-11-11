# `Next.Systems.Announcement.NextActions.ReadAnnouncement`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/next_actions/read_announcement.ex#L1)

The To-do of one unread announcement. There is one per recipient, keyed by
the announcement (`key/1`). Title and summary are read from the announcement
when the To-do is shown, so edits show at once. Opening the announcement
page clears it (`Next.Systems.Announcement.Public.mark_read/1`).

# `key`

The next-action key of the announcement with `announcement_id`.

# `params`

The next-action params of the announcement with `announcement_id`.

# `priority`

The next-action priority of the announcement's To-do: a high announcement
comes before other To-dos (which have the default `:normal`), a normal
announcement after them.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
