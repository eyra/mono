# `Systems.BFF.PageController`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/page_controller.ex#L1)

# `auth_module`

# `print_auth_roles`

# `show`

The view model of `page` as `%{"blocks" => [...], "markup" => [...]}`, for the page's
params in the query (`Systems.BFF.Blocks.view_model/2`, which raises on bad markup).
401 when signed out, before the page is looked up; 404 for a page the spec doesn't
list or no system serves.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
