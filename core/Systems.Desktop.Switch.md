# `Systems.Desktop.Switch`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/desktop/_switch.ex#L1)

Signal handler for the Desktop system.

Desktop is a consumer of NextAction — it renders the next-best-action
banner on /desktop. Listen for NextAction changes on the affected
user and refresh the Desktop page so the banner updates live (in
addition to the to-do count badge that the menus live-hook already
refreshes).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
