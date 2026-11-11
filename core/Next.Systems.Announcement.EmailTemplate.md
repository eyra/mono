# `Next.Systems.Announcement.EmailTemplate`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/email_template.ex#L1)

The email of a high-priority announcement, readable on its own: the title,
the full body and a link to the announcement page, without the summary. The
HTML part has the cleaned body; the plain-text part has its text.

The link is the plain page address. Opening the email or following the link
changes nothing in Next; only opening the page marks the announcement read.

# `announcement_html`

# `announcement_text`

# `email`

The email of `announcement`, without recipients, rendered in the current locale.

# `to_text`

The text of rich-text HTML, with blocks and line breaks as new lines, list
items as "- " lines and links followed by their address.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
