# `Systems.Admin.ClientActivityViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/client_activity_view_builder.ex#L1)

ViewBuilder for the Admin ClientActivityView.

Only builds data for system admins (`is_admin?: true`).

Three levels, picked by the assigns:
- no `client_id`: clients with their assignment count
- `client_id`: that client's assignments
- `assignment_id`: the assignment's details and team

Who the client of an assignment is, is decided in `Systems.Admin.Queries.assignment_client_query/0`.

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
