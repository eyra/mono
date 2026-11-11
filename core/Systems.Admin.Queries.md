# `Systems.Admin.Queries`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/_queries.ex#L1)

# `assignment_client_query`

Maps every project assignment to its client: one row `%{assignment_id, client_id}`.

This is the only place that decides who the client of an assignment is, so the
Client activity tab can move from users to organisations by changing this query.

The client is the first (original) owner of the assignment's project: the
project's creator. Assignments whose project has no owner left are not mapped.

Only items on a project's root node are counted; no code creates nested
project nodes today.

Pass an assignment id to map only that assignment.

# `client_assignment_query`

Project assignments with their client and project item, filtered by the
Client activity filters (`:this_year`, `:published`).

Bindings: `:client`, `:assignment`, `:item`, `:user`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
