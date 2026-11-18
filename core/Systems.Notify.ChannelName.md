# `Systems.Notify.ChannelName`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/channel_name.ex#L1)

The channel of a `Systems.Notify.MessageModel`: a string column whose names
are checked against `Mica.SaaS.notify_channels/0` at runtime, not at compile
time.

- `cast/1` accepts an atom or a string that names a channel of the
  composition and returns the atom. Any other name is an error.
- `dump/1` writes the name as a string.
- `load/1` returns the atom for a channel of the composition. A stored name
  the composition doesn't have loads as the string itself, so the row still
  loads and only its own message fails (`Systems.Notify.Channel.adapter/1`
  returns `{:error, :unknown_channel}`).

# `embed_as`

# `equal?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
