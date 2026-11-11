# `Next.Systems.Announcement.Model`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/announcement/model.ex#L1)

An announcement written by a system admin for a group of creators. The body is
the HTML of the rich-text editor (Trix), stored cleaned
(`Frameworks.Pixel.RichText.clean/1`).

`recipient_ids` is the audience, resolved once when it is published
(`Next.Systems.Announcement.Public.publish_announcement/4`); it does not change after that.
It can be long, so reads leave it out unless they select it.

# `changeset`

# `fields`

The fields a save can change.

# `fixed_after_publishing`

The fields that can't change once it is published. The audience can't
either: `recipient_ids` is never cast.

# `kinds`

# `preload_graph`

# `priorities`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
