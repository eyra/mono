# `Systems.Email.Model`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/email/model.ex#L1)

A notification email, as `Systems.Email.Public.deliver_later!/1` queues it.

`subject` and `html_message` are optional. Without a subject the email has
the default one; without `html_message` the HTML part is made from the
plain-text `message`.

# `changeset`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
