# `Systems.Assignment.ErrorHTML`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/error_html.ex#L1)

Renders the pages shown when a participant follows a link that leads nowhere:
the assignment has no budget capacity left, the assignment is not published,
or an external survey returns to a task the researcher has removed.

It lives in the Assignment system rather than the generic `MicaWeb.ErrorHTML`
because both the copy and the meaning are assignment-specific; it reuses the
shared `MicaWeb.ErrorHTML.error/1` chrome for the layout.

# `auth_module`

# `full`

# `handle_info`

# `print_auth_roles`

# `render`

# `task_unavailable`

# `unavailable`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
