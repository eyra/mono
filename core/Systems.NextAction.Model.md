# `Systems.NextAction.Model`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/next_action/model.ex#L1)

A next action (To-do) of a user.

`priority` is stored as an integer (`low: -10`, `normal: 0`, `high: 10`) and
the database only accepts these values (`next_actions_priority_check`), so a
value the code can't load is refused when it is written instead of breaking
every list of that user's next actions. A new level needs a migration
that widens that constraint, and two releases: first one that can read the
new value, then one that writes it.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
