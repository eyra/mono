# `Next.Systems.Announcement.Public`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/_public.ex#L1)

Create, change and read announcements and their recipients.

A recipient row (`Next.Systems.Announcement.RecipientModel`) records that one user
received an announcement and when they read it. Only users with a recipient
row may open a published announcement (`get_received/2`).

# `audience_filters`

The filters that narrow the audience of an announcement. The audience is
always creators; these come on top, combined with AND.

# `count_audiences`

The number of recipients each published announcement was published to, as
a map from announcement id to count. Unpublished announcements count 0.

# `create_announcement`

Creates an announcement by `author`.

# `deliver_announcement`

Gives every recipient of a published announcement a recipient row and a
To-do, with one insert for the rows and batched inserts for the To-dos.
For a high-priority announcement it also queues one email per recipient
(`Next.Systems.Announcement.EmailTemplate`), in batches. Recipients who already
have a row are skipped, so running it again adds and sends nothing. Users
deleted since publication are left out. Returns `{:ok, count}` with the
number of recipients added.

# `get_announcement`

# `get_announcement!`

# `get_received`

The recipient row of `user` for the announcement with `announcement_id`, with
the announcement preloaded, or `nil` when the user did not receive it or it
is not published.

# `list_announcements`

All announcements, newest first.

# `list_audience_ids`

The ids of the users an announcement for the audience of `filters` and
`query` reaches: creators with a confirmed account that match every filter
and every word of the search, with the matching of Admin → Users
(`Systems.Admin.Public.list_matching_users/2`). Filters other than
`audience_filters/0` are ignored.

# `list_received`

The published announcements `user` received, as recipient rows with the announcement
preloaded, newest publication first. `limit: n` returns only the `n` newest.

# `list_recipients`

The recipient rows of `announcement`.

# `mark_read`

Marks the announcement read for the recipient and clears its To-do.
`read_at` is set only once and keeps the time of the first opening. The
To-do is cleared on every call, so one that is left or comes back after
the first opening goes too. Returns the recipient with `read_at` set.

# `publish_announcement`

Publishes an unpublished announcement to the audience of `filters` and
`query` (`list_audience_ids/2`). The audience is resolved here, once, and
stored on the announcement; a job then gives every recipient a recipient
row and a To-do (`deliver_announcement/1`).

`shown_count` is the recipient count the admin saw and confirmed. When the
audience has changed since, nothing is published and the result is
`{:error, {:audience_changed, count}}` with the current count.

Returns `{:error, :no_recipients}` when the audience is empty and
`{:error, :already_published}` when it was published before.

# `update_announcement`

Changes an announcement and dispatches `{:announcement, :updated}`, so the
pages that show it refresh. Nothing is sent again and the recipients keep
their read status.

`announcement` is the copy the change was made on, such as the one a form
opened. Returns `{:error, :changed_since_loaded}` when the announcement was
saved since that copy was loaded, so two forms can't undo each other's
changes. After publication only the title, summary and body may change
(`Next.Systems.Announcement.Model.fixed_after_publishing/0`). Returns
`{:error, :already_published}` when the change touches another field, and
when the copy was loaded before it was published. The row is locked and
checked in the same transaction as the update.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
