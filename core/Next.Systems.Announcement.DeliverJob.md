# `Next.Systems.Announcement.DeliverJob`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/deliver_job.ex#L1)

Gives the recipients of a just-published announcement their recipient rows
and To-dos, and for a high-priority announcement their emails
(`Next.Systems.Announcement.Public.deliver_announcement/1`). Running it again
adds and sends nothing, so a retry is safe.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
