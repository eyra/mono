# `Systems.Pool.ParticipantsViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/participants_view_builder.ex#L1)

ViewBuilder for `Pool.ParticipantsView` — read-only list of pool participants.

Provides:
- title: section title
- people: rendered participant rows (avatar, name, email, info), capped at @max_participants
- participant_count: total after search filter (uncapped) — drives the count next to the title
- search_placeholder / query_string: powers the SearchBar

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
