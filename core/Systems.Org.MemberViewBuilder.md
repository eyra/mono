# `Systems.Org.MemberViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/org/member_view_builder.ex#L1)

ViewBuilder for Org.MemberView (members tab).

Provides the data needed by PeopleEditorView:
- title: The section title
- people: Current org members (filtered, searched, capped at @max_members)
- users: Available users that can be added as members
- user_count: Total members after filter+search (uncapped) — drives the
  count next to the "Members" title
- filter_labels: Pixel.Selector items for the :external and :recent chips
- search_placeholder / query_string: powers the SearchBar
- domain_banner: Banner for domain-matched users with specific count

Filters use OR semantics (a member is shown if they match ANY active
chip). No chips selected = show everything. The :recent chip selects
members whose role was granted in the current ISO week (Mon 00:00 UTC
onward).

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
