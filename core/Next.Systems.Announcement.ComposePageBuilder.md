# `Next.Systems.Announcement.ComposePageBuilder`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/compose_page_builder.ex#L1)

View model of the page to compose an announcement
(`Next.Systems.Announcement.ComposePage`): the labels of the form and, for an
unpublished one, the audience: who it reaches with the chosen filters and
search, and whether they get an email.

Assigns read: `announcement` (the one being composed; the page's model until
the page has opened it), `audience_filters` (from
`Next.Systems.Announcement.Public.audience_filters/0`), `audience_query` (the
search words), `priority` (the priority chosen in the form) and
`compose_notice` (`:already_published`, `:changed_since_loaded`,
`:audience_changed` or `:no_recipients` after a refused save or publish).
A published one has no audience to choose, only `published`: what saving it
does, and the notice of a refused save.

Only system admins with the `announcements` flag on (`allowed?`) get the
audience or `published`.

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
